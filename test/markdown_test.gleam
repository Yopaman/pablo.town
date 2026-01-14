import gleeunit
import glimra
import glimra/theme
import lustre/element/html
import pages/blog
import tempo/date

import internal/markdown

pub fn main() {
  gleeunit.main()
}

pub fn markdown_test() {
  let syntax_highlighter =
    glimra.new_syntax_highlighter()
    |> glimra.set_theme(theme.default_theme())
  let post =
    markdown.from_markdown_file("test/fake_article.md", syntax_highlighter)
  let assert Ok(my_date) = date.new(2005, 11, 12)
  assert post
    == blog.Post("test", "", my_date, ["tag1", "tag2", "tag3"], [
      html.h1([], [html.text("Hello")]),
      html.text(""),
      html.h2([], [html.text("bonjour")]),
      html.text(""),
      html.p([], [
        html.text("test "),
        html.strong([], [html.text("test")]),
        html.text(" "),
        html.em([], [html.text("test")]),
      ]),
    ])
}
