import blogatto
import blogatto/config
import blogatto/config/markdown
import blogatto/config/markdown/code
import lustre/attribute
import lustre/element
import lustre/element/html
import pages/index
import pages/list
import pages/post

pub fn config() -> config.Config(Nil) {
  let md =
    markdown.default()
    |> markdown.markdown_path("./data/posts")
    |> markdown.route_prefix("blog")
    |> markdown.template(post.view)
    |> markdown.syntax_highlighting(syntax_highlighting())
    |> markdown.blockquote(fn(children) { todo })

  config.new("https://pablo.town")
  |> config.output_dir("./dist")
  |> config.static_dir("./static")
  |> config.markdown(md)
  |> config.route("/", index.view)
  |> config.route("/blog", list.view)
}

pub fn main() {
  let cfg = config()

  let assert Ok(Nil) = blogatto.build(cfg)
}

fn token(class_name: String) -> fn(String) -> element.Element(msg) {
  fn(value) {
    html.span([attribute.class("token " <> class_name)], [element.text(value)])
  }
}

pub fn syntax_highlighting() -> code.SyntaxHighlightingConfig(msg) {
  code.default()
  |> code.keyword(token("smalto-keyword"))
  |> code.string(token("smalto-string"))
  |> code.number(token("smalto-number"))
  |> code.comment(token("smalto-comment"))
  |> code.function(token("smalto-function"))
  |> code.operator(token("smalto-operator"))
  |> code.punctuation(token("smalto-punctuation"))
  |> code.type_(token("smalto-type"))
  |> code.module(token("smalto-module"))
  |> code.variable(token("smalto-variable"))
  |> code.constant(token("smalto-constant"))
  |> code.builtin(token("smalto-builtin"))
  |> code.tag(token("smalto-tag"))
  |> code.attribute(token("smalto-attribute"))
  |> code.selector(token("smalto-selector"))
  |> code.property(token("smalto-property"))
  |> code.regex(token("smalto-regex"))
}
