use std::fs::{self, File};
use std::io::{Error, ErrorKind, Write};
use std::path::PathBuf;

use rand::RngExt;
use rand::distr::{Alphanumeric, SampleString};

/// 生成指定长度的随机数据
pub(crate) fn random_bytes(len: usize) -> Vec<u8> {
    let rng = rand::rng();
    rng.random_iter().take(len).collect()
}

/// 生成指定长度的随机字符串(a-z0-9)
pub(crate) fn random_string(len: usize) -> String {
    Alphanumeric.sample_string(&mut rand::rng(), len)
}

/// 值和盐进行异或
pub(crate) fn transform_xor(value: &[u8], salt: &[u8]) -> Vec<u8> {
    let salt_len = salt.len();
    (0..value.len())
        .map(|i| value[i] ^ salt[i % salt_len])
        .collect()
}

/// 简单的提取链接的域名
pub(crate) fn simple_to_domain(url: &str) -> String {
    if url.starts_with("http://") || url.starts_with("https://") {
        let arr: Vec<_> = url.split('/').collect();
        arr[2].trim().to_string()
    } else {
        let arr: Vec<_> = url.split('/').collect();
        arr[0].trim().to_string()
    }
}

/// 判断域名是否包含在地址列表中
/// 只要有一个二级域名包含返回真
pub(crate) fn contains_domain(domain: &str, urls: Vec<&str>) -> bool {
    let domain_parts: Vec<&str> = domain.split('.').collect();
    if domain_parts.len() < 2 {
        return false;
    }
    let target = &domain_parts[domain_parts.len() - 2..];

    for url_str in urls {
        let host = simple_to_domain(url_str);
        let host_parts: Vec<&str> = host.split('.').collect();
        if host_parts.len() < 2 {
            continue;
        }
        let host_target = &host_parts[host_parts.len() - 2..];
        if host_target == target {
            return true;
        }
    }
    false
}

struct DropCleanUp(PathBuf);

impl Drop for DropCleanUp {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

/// 原子写入, 确保文件写入到磁盘, 防止中间态出现错误导致数据丢失
/// 只考虑文件, 绝对路径
pub(crate) fn atomic_write(file_path: &str, buf: &[u8]) -> Result<(), Error> {
    let file_path_buf = PathBuf::from(file_path);

    assert!(file_path_buf.is_absolute());

    let (mut file, temp_path) = loop {
        let path = PathBuf::from(format!("{}.{}", file_path, random_string(6)));

        match File::options().write(true).create_new(true).open(&path) {
            Ok(file) => break (file, path),
            Err(ref err) if err.kind() == ErrorKind::AlreadyExists => continue,
            Err(err) => return Err(err),
        }
    };

    let cleanup = DropCleanUp(temp_path);

    if let Ok(meta) = fs::metadata(&file_path_buf) {
        file.set_permissions(meta.permissions())?;
    }

    file.write_all(buf)?;
    file.sync_all()?;

    fs::rename(&cleanup.0, file_path_buf)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use tempfile::tempdir;

    use super::*;

    #[test]
    fn test_random_bytes() {
        assert_ne!(random_bytes(10), random_bytes(10));
    }

    #[test]
    fn test_simple_to_domain() {
        assert_eq!(
            simple_to_domain("https://chat.deepseek.com/path"),
            "chat.deepseek.com"
        );
        assert_eq!(
            simple_to_domain("http://www.example.com/index.html"),
            "www.example.com"
        );
        assert_eq!(simple_to_domain("www.github.com"), "www.github.com");
        assert_eq!(simple_to_domain("example.com/path"), "example.com");
        assert_eq!(simple_to_domain("localhost:8080"), "localhost:8080");
    }

    #[test]
    fn test_contains_domain() {
        assert!(contains_domain(
            "deepseek.com",
            vec!["https://chat.deepseek.com/", "www.github.com"]
        ));
        assert!(contains_domain(
            "chat.deepseek.com",
            vec!["https://a.b.deepseek.com/"]
        ));
        assert!(contains_domain("co.uk", vec!["https://example.co.uk/"]));

        assert!(!contains_domain("com", vec!["https://chat.deepseek.com/"])); // 只有顶级域
        assert!(!contains_domain(
            "deepseek.com",
            vec!["https://deepseek.com.cn/"]
        ));
        assert!(!contains_domain(
            "xdeepseek.com",
            vec!["https://chat.deepseek.com/"]
        ));
        assert!(!contains_domain("example.com", vec!["https://github.com/"]));
    }

    /// 辅助：创建已存在的目标文件，返回绝对路径字符串
    fn setup(dir: &std::path::Path, content: &[u8]) -> String {
        let p = dir.join("out.txt");
        fs::write(&p, content).unwrap();
        p.to_str().unwrap().to_string()
    }

    /// 覆盖已存在文件，内容正确，且无临时文件残留
    #[test]
    fn overwrites_and_leaves_no_temp_file() {
        let dir = tempdir().unwrap();
        let path = setup(dir.path(), b"old");

        atomic_write(&path, b"new content").unwrap();

        assert_eq!(fs::read(&path).unwrap(), b"new content");
        let entries: Vec<_> = fs::read_dir(dir.path()).unwrap().collect();
        assert_eq!(entries.len(), 1, "有临时文件残留");
    }

    /// 覆盖后保留原文件权限
    #[cfg(unix)]
    #[test]
    fn preserves_permissions() {
        use std::os::unix::fs::PermissionsExt;

        let dir = tempdir().unwrap();
        let path = setup(dir.path(), b"old");
        fs::set_permissions(&path, fs::Permissions::from_mode(0o600)).unwrap();

        atomic_write(&path, b"secret").unwrap();

        let mode = fs::metadata(&path).unwrap().permissions().mode() & 0o7777;
        assert_eq!(mode, 0o600);
    }

    /// 并发写入后文件内容始终是完整的一份，不会出现混合
    #[test]
    fn concurrent_writes_stay_consistent() {
        use std::sync::Arc;
        use std::thread;

        let dir = Arc::new(tempdir().unwrap());
        let path = Arc::new(setup(dir.path(), b"initial"));
        let payloads = [vec![b'A'; 100_000], vec![b'B'; 100_000]];

        let handles: Vec<_> = (0..8)
            .map(|i| {
                let path = Arc::clone(&path);
                let data = payloads[i % 2].clone();
                thread::spawn(move || atomic_write(&path, &data).unwrap())
            })
            .collect();
        for h in handles {
            h.join().unwrap();
        }

        let content = fs::read(&*path).unwrap();
        assert_eq!(content.len(), 100_000);
        assert!(
            content.iter().all(|&c| c == b'A') || content.iter().all(|&c| c == b'B'),
            "文件内容出现混合，原子性被破坏"
        );
    }
}
