fn main() {
    #[cfg(target_os = "freebsd")]
    println!("cargo:rustc-link-search=native=/usr/local/lib");
}