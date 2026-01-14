import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glimra
import glimra/theme
import internal/markdown
import pages/blog
import simplifile
import tempo/date

import pages/index.{Infos, Website}
import pages/list as list_page

import lustre/ssg

pub fn main() {
  let syntax_highlighter =
    glimra.new_syntax_highlighter()
    |> glimra.set_theme(theme.default_theme())

  let posts = parse_markdown_files(syntax_highlighter)
  // echo posts

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
    |> glimra.add_static_stylesheet(syntax_highlighter: syntax_highlighter)
    |> ssg.add_static_route("/blog", list_page.view("posts", posts))
    |> add_posts_routes("/blog", posts)
    |> ssg.use_index_routes
    |> ssg.build

  case build {
    Ok(_) -> io.println("Build succeeded!")
    Error(e) -> {
      echo e
      io.println("Build failed!")
    }
  }

  // HACK: todo: pull request to lustre/ssg to have a better way to do this
  case add_posts_imgs(posts) {
    Ok(_) -> io.println("Images added successfully!")
    Error(e) -> {
      echo e
      io.println("Error adding images!")
    }
  }
}

fn parse_markdown_files(
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> List(blog.Post(_)) {
  let assert Ok(files) = simplifile.get_files("data/posts")
  files
  |> list.filter(fn(e) { e |> string.ends_with(".md") })
  |> list.map(fn(e) { e |> markdown.from_markdown_file(syntax_highlighter) })
}

fn add_posts_routes(
  config: ssg.Config(_, _, _),
  path: String,
  posts: List(blog.Post(_)),
) -> ssg.Config(_, _, _) {
  posts
  |> list.fold(config, fn(config, post) {
    config |> ssg.add_static_route(path <> "/" <> post.id, blog.view(post))
  })
}

fn add_posts_imgs(posts: List(blog.Post(_))) {
  posts
  |> list.map(fn(p) { "data/posts/" <> p.id <> "/img" })
  |> list.try_map(fn(path) {
    simplifile.copy_directory(
      path,
      "dist/blog/"
        <> path |> filepath.split() |> list.drop(2) |> string.join("/"),
    )
  })
}
// fn get_all_images(path: String) -> List(String) {
//   let assert Ok(paths) = simplifile.get_files(path)
//   paths
//   |> list.filter(fn(ext) {
//     [".png", ".jpg", ".jpeg", ".gif"]
//     |> list.fold(True, fn(acc, e) { string.ends_with(ext, e) || acc })
//   })
// }
