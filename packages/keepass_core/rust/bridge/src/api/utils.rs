use rand::RngCore;

/// 生成指定长度的随机数据
pub(crate) fn random_bytes(len: usize) -> Vec<u8> {
    let mut random_bytes = vec![0u8; len];
    rand::thread_rng()
        .try_fill_bytes(&mut random_bytes)
        .unwrap();
    random_bytes
}

/// 值和盐进行异或
pub(crate) fn transform_xor(value: &Vec<u8>, salt: &Vec<u8>) -> Vec<u8> {
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

#[cfg(test)]
mod tests {
    use super::*;

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
}
