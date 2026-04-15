import blogatto/post.{type Post}
import components/page
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(post: Post(Nil), _all_posts: List(Post(Nil))) -> Element(_) {
  page.page(
    post.title,
    html.section(
      [attribute.id("post")],
      [
        html.h1([attribute.class("title")], [html.text(post.title)]),
      ]
        |> list.append(post.contents),
    ),
    True,
    [],
  )
}
