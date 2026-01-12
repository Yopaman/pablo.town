import components/page
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import pages/blog
import tempo/date

pub fn view(title: String, posts: List(blog.Post(_))) -> Element(_) {
  page.page(
    title,
    html.section(
      [attribute.id("list")],
      [html.h1([], [html.text(title)])]
        |> list.append(
          posts
          |> list.map(fn(post: blog.Post(_)) {
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
                  html.text(post.date |> date.to_string),
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
