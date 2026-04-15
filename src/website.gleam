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

pub fn main() {
  let md =
    markdown.default()
    |> markdown.markdown_path("./data/posts")
    |> markdown.route_prefix("blog")
    |> markdown.template(post.view)
    |> markdown.syntax_highlighting(syntax_highlighting())

  let cfg =
    config.new("https://pablo.town")
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.markdown(md)
    |> config.route("/", index.view)
    |> config.route("/blog", list.view)

  let assert Ok(Nil) = blogatto.build(cfg)
  // let build =
  //   ssg.new("./dist")
  //   |> ssg.add_static_route(
  //     "/",
  //     index.view(
  //       Infos(
  //         name: "Pablo",
  //         birth_date: date.from_string("2002-04-26")
  //           |> result.unwrap(date.unix_epoch),
  //         interests: ["Cybersecurity", "Computer Science", "Game Development"],
  //         links: [
  //           Website("Github", "https://github.com/yopaman"),
  //           Website("Bluesky", "https://bsky.app/profile/pablo.town"),
  //         ],
  //         email: "contact[at]this_domain",
  //       ),
  //       syntax_highlighter,
  //     ),
  //   )
  //   |> ssg.add_static_dir("./static")
  //   |> glimra.add_static_stylesheet(syntax_highlighter: syntax_highlighter)
  //   |> ssg.add_static_route("/blog", list_page.view("Posts", posts))
  //   |> add_posts_routes("/blog", posts)
  //   |> ssg.use_index_routes
  //   |> ssg.build

  // case build {
  //   Ok(_) -> io.println("Build succeeded!")
  //   Error(e) -> {
  //     echo e
  //     io.println("Build failed!")
  //   }
  // }

  // // HACK: todo: pull request to lustre/ssg to have a better way to do this
  // case add_posts_imgs(posts) {
  //   Ok(_) -> io.println("Images added successfully!")
  //   Error(e) -> {
  //     echo e
  //     io.println("Error adding images!")
  //   }
  // }
}
