import blogatto/post.{type Post}
import components/page
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import internal/utils
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(posts: List(Post(_))) -> Element(Nil) {
  page.page(
    "Blog",
    html.section(
      [attribute.id("list")],
      [html.h1([], [html.text("Blog")])]
        |> list.append(
          posts
          |> list.map(fn(post: Post(_)) {
            html.article(
              [attribute.class("post")],
              [
                html.a(
                  [
                    attribute.href("/blog/" <> post.slug),
                    attribute.class("post-title"),
                  ],
                  [html.text(post.title)],
                ),
                html.p([attribute.class("date")], [
                  html.text(post.date |> utils.timestamp_to_string),
                ]),
              ]
                |> list.append(
                  post.extras
                  |> dict.get("tags")
                  |> result.unwrap("")
                  |> string.replace(", ", ",")
                  |> string.split(",")
                  |> list.map(fn(tag) {
                    html.a(
                      [
                        attribute.class("chip tag"),
                        attribute.href("/blog/tag/" <> tag),
                      ],
                      [html.text(tag)],
                    )
                  }),
                ),
            )
          }),
        ),
    ),
    False,
    [],
  )
}
