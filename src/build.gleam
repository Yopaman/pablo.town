import gleam/dict
import gleam/io
import gleam/result
import mork
import mork/to_lustre
import pages/blog
import simplifile
import tempo/date

import pages/index.{Infos, Website}
import pages/list as list_page

import lustre/element.{type Element}

import lustre/ssg

pub fn main() {
  let test_posts = [
    #(
      "test",
      blog.Post(
        "test",
        "test",
        date.current_local(),
        ["tag1", "tag2"],
        mork.parse("bonjour test test") |> to_lustre.to_lustre,
      ),
    ),

    #(
      "test2",
      blog.Post(
        "test2",
        "test2",
        date.current_local(),
        ["tag1", "tag2"],
        mork.parse("bonjour2 **test2** test2") |> to_lustre.to_lustre,
      ),
    ),
  ]

  let build =
    ssg.new("./dist")
    |> ssg.add_static_route(
      "/",
      index.view(Infos(
        name: "Pablo",
        birth_date: date.from_string("2002-04-26")
          |> result.unwrap(date.unix_epoch),
        interests: ["Cybersecurity", "Computer Science", "Game Development"],
        links: [
          Website("Github", "https://github.com/yopaman"),
          Website("Bluesky", "https://bsky.app/profile/pablo.town"),
        ],
        email: "contact[at]this_domain",
      )),
    )
    |> ssg.add_static_dir("./static")
    |> ssg.add_static_route(
      "/blog/index",
      list_page.view("posts", dict.from_list(test_posts) |> dict.values),
    )
    |> ssg.add_dynamic_route("/blog", dict.from_list(test_posts), blog.view)
    |> ssg.build

  case build {
    Ok(_) -> io.println("Build succeeded!")
    Error(e) -> {
      echo e
      io.println("Build failed!")
    }
  }
}

fn parse_markdown_files() -> dict.Dict(String, Element(_)) {
  todo
}
