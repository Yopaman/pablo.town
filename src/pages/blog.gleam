import components/page
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import tempo

pub fn view(post: Post(_)) -> Element(_) {
  page.page(
    post.title,
    html.section(
      [attribute.id("post")],
      [
        html.h1([attribute.class("title")], [html.text(post.title)]),
      ]
        |> list.append(post.content),
    ),
  )
}

pub type Post(a) {
  Post(
    title: String,
    id: String,
    date: tempo.Date,
    tags: List(String),
    content: List(Element(a)),
  )
}

pub fn get_post_link(post: Post(_)) -> String {
  "/blog/" <> post.id
}

pub fn get_tag_link(tag: String) -> String {
  "/blog/tag/" <> tag
}
