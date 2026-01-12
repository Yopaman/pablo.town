import components/page
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mork/document
import tempo

pub fn view(post: Post) -> Element(_) {
  page.page(
    post.title,
    html.section([attribute.id("page")], [
      html.h1([attribute.class("title")], [html.text(post.title)]),
    ]),
  )
}

pub type Post {
  Post(
    title: String,
    id: String,
    date: tempo.Date,
    tags: List(String),
    content: document.Document,
  )
}

pub fn get_post_link(post: Post) -> String {
  "/blog/" <> post.id
}

pub fn get_tag_link(tag: String) -> String {
  "/blog/tag/" <> tag
}
