import birl
import components/page
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import pages/blog

pub fn view(title: String, posts: List(blog.Post)) -> Element(_) {
  page.page(
    title,
    html.section(
      [attribute.id("list")],
      [html.h1([], [html.text(title)])]
        |> list.append(
          posts
          |> list.map(fn(post: blog.Post) {
            html.article(
              [attribute.class("post"), event.on_click("")],
              [
                html.a(
                  [
                    attribute.href(post |> blog.get_post_link),
                    attribute.class("post-title"),
                  ],
                  [html.text(post.title)],
                ),
                html.p([attribute.class("date")], [
                  html.text(post.date |> birl.to_naive_date_string),
                ]),
              ]
                |> list.append(
                  post.tags
                  |> list.map(fn(tag) {
                    html.a(
                      [
                        attribute.class("chip tag"),
                        attribute.href(tag |> blog.get_tag_link),
                      ],
                      [html.text(tag)],
                    )
                  }),
                ),
            )
          }),
        ),
    ),
  )
}
