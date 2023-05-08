fn foo() -> usize {
    1
}

#[test]
fn test_foo() {
    assert_eq!(foo(), 1);
}

fn main() {
    println!("Hello, world!");
    println!("testing");
}
