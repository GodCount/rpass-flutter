#[cfg(feature = "save_kdbx4")]
use zenflate::{CompressionError, CompressionLevel, Compressor};
use zenflate::{DecompressionError, Decompressor, Unstoppable};

pub trait Compression {
    #[cfg(feature = "save_kdbx4")]
    fn compress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error>;
    fn decompress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error>;
}

pub struct NoCompression;

impl Compression for NoCompression {
    #[cfg(feature = "save_kdbx4")]
    fn compress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error> {
        Ok(in_buffer.to_vec())
    }
    fn decompress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error> {
        Ok(in_buffer.to_vec())
    }
}

pub struct GZipCompression;

impl Compression for GZipCompression {
    #[cfg(feature = "save_kdbx4")]
    fn compress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error> {
        let bound = Compressor::gzip_compress_bound(in_buffer.len());
        let mut res = vec![0u8; bound];

        let mut compressor = Compressor::new(CompressionLevel::balanced());

        // Can unwrap and the error will not occur
        let len = compressor
            .gzip_compress(in_buffer, &mut res, Unstoppable)
            .unwrap();

        res.truncate(len);

        Ok(res)
    }

    fn decompress(&self, in_buffer: &[u8]) -> Result<Vec<u8>, std::io::Error> {
        // gzip RFC1952: a valid gzip file has an ISIZE field in the
        // footer, which is a little-endian u32 number representing the
        // decompressed size. This is ideal for libdeflate, which needs
        // preallocating the decompressed buffer.
        let isize = {
            let isize_start = in_buffer.len() - 4;
            let isize_bytes = &in_buffer[isize_start..];
            let mut ret: u32 = isize_bytes[0] as u32;
            ret |= (isize_bytes[1] as u32) << 8;
            ret |= (isize_bytes[2] as u32) << 16;
            ret |= (isize_bytes[3] as u32) << 24;
            ret as usize
        };

        let mut res = vec![0u8; isize];
        let _ = Decompressor::new()
            .with_max_output_size(Some(isize))
            .gzip_decompress(in_buffer, &mut res, Unstoppable)
            .map_err(|err| match err {
                DecompressionError::BadData => {
                    std::io::Error::new(std::io::ErrorKind::InvalidData, "bad compressed data")
                }
                DecompressionError::InvalidHeader => {
                    std::io::Error::new(std::io::ErrorKind::InvalidData, "invalid gzip header")
                }
                DecompressionError::ChecksumMismatch => {
                    std::io::Error::new(std::io::ErrorKind::InvalidData, "checksum mismatch")
                }
                _ => panic!("An unexpected error occurred {:?}", err),
            })?;

        Ok(res)
    }
}
