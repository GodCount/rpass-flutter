use proc_macro::TokenStream;
use quote::quote;
use syn::parse::{Parse, ParseStream, Result};
use syn::{Ident, LitStr, Token, braced, parse_macro_input};

struct ConstantInput {
    struct_name: Ident,
    pairs: Vec<(Ident, LitStr)>,
}

impl Parse for ConstantInput {
    fn parse(input: ParseStream) -> Result<Self> {
        let struct_name: Ident = input.parse()?;
        let content;
        braced!(content in input);

        let mut pairs = Vec::new();

        while !content.is_empty() {
            let name: Ident = content.parse()?;
            content.parse::<Token![=]>()?;

            let value: LitStr = content.parse()?;
            pairs.push((name, value));

            if !content.is_empty() {
                content.parse::<Token![,]>()?;
            }
        }
        Ok(ConstantInput { struct_name, pairs })
    }
}


/// 创建rust 字符串常量, 并生成一个 dart对象同时包含常量

#[proc_macro]
pub fn frb_string_constant(input: TokenStream) -> TokenStream {
    let ConstantInput { struct_name, pairs } = parse_macro_input!(input as ConstantInput);

    let const_defs = pairs.iter().map(|(name, value)| {
        quote! {
            const #name: &str = #value;
        }
    });

    let dart_code_parts: Vec<String> = pairs
        .iter()
        .map(|(name, value)| format!(r#"static const {}="{}";"#, name, value.value()))
        .collect();
    let dart_code_str = dart_code_parts.concat();

    let expanded = quote! {
        #(#const_defs)*

        #[frb(unignore, non_hash, non_eq, dart_code = #dart_code_str)]
        pub struct #struct_name {}
    };

    TokenStream::from(expanded)
}
