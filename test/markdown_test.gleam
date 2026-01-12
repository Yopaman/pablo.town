import gleeunit

import internal/markdown

pub fn main() {
  gleeunit.main()
}

pub fn markdown_test() {
  let #(frontmatter, content) = markdown.parse_post("test/fake_article.md")
  echo frontmatter
  echo content
  assert 1 == 1
}
