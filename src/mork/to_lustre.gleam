// Copyright 2026 git.liten.app/krig/mork/src/branch/main/to_lustre

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Modifications:
// - Modified by Yopaman (contact@pablo.town), 2026

import gleam/bool.{guard}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import gleam/uri
import glimra
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mork/document.{
  type Alignment, type Block, type Cell, type Destination, type Document,
  type FootnoteData, type Inline, type LinkData, type ListItem, type ListPack,
  type THead, Absolute, Anchor, Autolink, BlockQuote, BulletList, Center,
  Checkbox, Code, CodeSpan, Delim, EmailAutolink, Emphasis, Empty, Footnote,
  FullImage, FullLink, HardBreak, Heading, Highlight, HtmlBlock, InlineFootnote,
  InlineHtml, Left, LinkData, Loose, Newline, OrderedList, Paragraph, RawHtml,
  RefImage, RefLink, Relative, Right, SoftBreak, Strikethrough, Strong, Table,
  Text, ThematicBreak, Tight,
}
import mork/internal/cache
import mork/internal/emojis.{type Emojis}
import mork/internal/entities
import mork/internal/escapes
import splitter.{type Splitter}

type Cache {
  Cache(
    entities: entities.Entities,
    emojis: Emojis,
    trim_start: Regexp,
    trim_end: Regexp,
    hspaces: Splitter,
    scheme: Splitter,
    query: Splitter,
    amp: Splitter,
    semi: Splitter,
    html: Splitter,
    codeblock: Splitter,
    esc: Splitter,
    colon: Splitter,
    starts_with_ws: fn(String) -> Bool,
    starts_with_p: fn(String) -> Bool,
    ends_with_ws: fn(String) -> Bool,
    ends_with_p: fn(String) -> Bool,
  )
}

fn create_cache(options: document.Options) -> Cache {
  let m = regexp.Options(case_insensitive: False, multi_line: True)
  let assert Ok(trim_start) = regexp.compile("^[ \\t]+", m)
  let assert Ok(trim_end) = regexp.from_string("[ \\t]+$")
  let hspaces = splitter.new([" ", "\t"])
  let scheme = splitter.new(["://", ":"])
  let query = splitter.new(["?"])
  let amp = splitter.new(["&", "\\"])
  let semi = splitter.new([";"])
  let html = splitter.new(["&", "<", ">", "\"", "\\"])
  let codeblock = splitter.new(["<", ">", "&", "\""])
  let esc = splitter.new(["\\"])
  let colon = splitter.new([":"])
  let re_starts_with_ws = cache.re_from_string("^\\s")
  let re_ends_with_ws = cache.re_from_string("\\s$")
  let re_starts_with_p = cache.re_from_string("^" <> cache.punctuation)
  let re_ends_with_p = cache.re_from_string(cache.punctuation <> "$")
  let starts_with_ws = fn(s: String) -> Bool {
    case s == "" {
      True -> True
      False -> regexp.check(re_starts_with_ws, s)
    }
  }
  let ends_with_ws = fn(s: String) -> Bool {
    case s == "" {
      True -> True
      False -> regexp.check(re_ends_with_ws, s)
    }
  }
  let starts_with_p = fn(s: String) -> Bool {
    regexp.check(re_starts_with_p, s)
  }
  let ends_with_p = fn(s: String) -> Bool { regexp.check(re_ends_with_p, s) }

  Cache(
    entities: entities.new(),
    emojis: case options.emojis {
      True -> emojis.new()
      False -> dict.new()
    },
    trim_start:,
    trim_end:,
    hspaces:,
    scheme:,
    query:,
    amp:,
    semi:,
    html:,
    codeblock:,
    esc:,
    colon:,
    starts_with_ws:,
    starts_with_p:,
    ends_with_ws:,
    ends_with_p:,
  )
}

pub fn to_lustre(
  doc: Document,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> List(Element(_)) {
  let cache = create_cache(doc.options)
  let output =
    list.map(doc.blocks, fn(block: Block) {
      block_to_lustre(cache, doc, block, Loose, syntax_highlighter)
    })
  with_footnotes(cache, doc, output, syntax_highlighter)
}

fn with_footnotes(
  cache: Cache,
  doc: Document,
  body: List(Element(_)),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) {
  use <- guard(dict.is_empty(doc.footnotes), body)
  let footnotes =
    list.sort(dict.to_list(doc.footnotes), fn(a, b) { string.compare(a.0, b.0) })
  list.flatten([
    body,
    [
      html.section(
        [attribute.class("footnotes"), attribute.data("footnotes", "")],
        [
          html.ol(
            [
              attribute.data("footnotes", ""),
            ],
            list.map(footnotes, footnote_entry(
              cache,
              doc,
              _,
              syntax_highlighter,
            )),
          ),
        ],
      ),
    ],
  ])
}

fn footnote_entry(
  cache: Cache,
  doc: Document,
  footnote: #(String, FootnoteData),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  // TODO: backrefs
  html.li(
    [
      attribute.id("fnref:" <> int.to_string({ footnote.1 }.num)),
    ],
    list.map({ footnote.1 }.blocks, block_to_lustre(
      cache,
      doc,
      _,
      Loose,
      syntax_highlighter,
    )),
  )
}

fn block_to_lustre(
  cache: Cache,
  doc: Document,
  block: Block,
  pack: ListPack,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  case block {
    ThematicBreak -> thematic_break_to_lustre(doc)
    Heading(level, id, _raw, inlines) ->
      heading_to_lustre(cache, doc, level, id, inlines)
    Code(lang, text) ->
      codeblock_to_lustre(cache, lang, text, syntax_highlighter)
    Paragraph(_text, inlines) -> paragraph_to_lustre(cache, doc, inlines, pack)
    BlockQuote(blocks) ->
      blockquote_to_lustre(cache, doc, blocks, syntax_highlighter)
    BulletList(pack, items) ->
      ul_to_lustre(cache, doc, pack, items, syntax_highlighter)
    OrderedList(pack, items, start) ->
      ol_to_lustre(cache, doc, pack, items, start, syntax_highlighter)
    HtmlBlock(raw) -> element.unsafe_raw_html("", "div", [], raw)
    Newline | Empty -> element.none()
    Table(header:, rows:) -> table_to_lustre(cache, doc, header, rows)
  }
}

fn th_to_lustre(cache: Cache, doc: Document, head: THead) {
  let text =
    head.inlines
    |> trim_around_newlines(cache, _)
    |> escape_text(cache, _)
    |> inlines_to_lustre(cache, doc, _)
  html.th(
    case head.align {
      Left -> []
      Center -> [attribute.attribute("align", "center")]
      Right -> [attribute.attribute("align", "right")]
    },
    text,
  )
}

fn tr_to_lustre(
  cache: Cache,
  doc: Document,
  aligns: List(Alignment),
  row: List(Cell),
) {
  html.tr(
    [],
    list.map(list.zip(row, aligns), fn(pair) {
      let #(cell, align) = pair
      let text =
        cell.inlines
        |> trim_around_newlines(cache, _)
        |> escape_text(cache, _)
        |> inlines_to_lustre(cache, doc, _)
      html.td(
        case align {
          Left -> []
          Center -> [attribute.attribute("align", "center")]
          Right -> [attribute.attribute("align", "right")]
        },
        text,
      )
    }),
  )
}

fn table_to_lustre(
  cache: Cache,
  doc: Document,
  header: List(THead),
  rows: List(List(Cell)),
) -> Element(_) {
  let head =
    html.thead([], [html.tr([], list.map(header, th_to_lustre(cache, doc, _)))])
  let aligns = list.map(header, fn(head) { head.align })
  let body = html.tbody([], list.map(rows, tr_to_lustre(cache, doc, aligns, _)))
  html.table([], [head, body])
}

fn ol_to_lustre(
  cache: Cache,
  doc: Document,
  pack: ListPack,
  items: List(ListItem),
  start: Option(Int),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  html.ol(
    start_attr(start),
    items_to_lustre(cache, doc, pack, items, syntax_highlighter),
  )
}

fn start_attr(start: Option(Int)) -> List(attribute.Attribute(msg)) {
  case start {
    Some(n) -> [attribute.attribute("start", int.to_string(n))]
    None -> []
  }
}

fn ul_to_lustre(
  cache: Cache,
  doc: Document,
  pack: ListPack,
  items: List(ListItem),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  html.ul([], items_to_lustre(cache, doc, pack, items, syntax_highlighter))
}

fn items_to_lustre(
  cache: Cache,
  doc: Document,
  pack: ListPack,
  items: List(ListItem),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> List(Element(_)) {
  list.map(items, item_to_lustre(cache, doc, pack, _, syntax_highlighter))
}

fn item_to_lustre(
  cache: Cache,
  doc: Document,
  pack: ListPack,
  item: ListItem,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  let blocks =
    list.map(item.blocks, fn(block) {
      block_to_lustre(cache, doc, block, pack, syntax_highlighter)
    })
  html.li([], blocks)
}

fn blockquote_to_lustre(
  cache: Cache,
  doc: Document,
  blocks: List(Block),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  choose_callout_to_render(cache, doc, blocks, syntax_highlighter)
}

fn emojify(callout_type: String) -> String {
  case callout_type {
    "important" -> "ℹ️"
    "note" -> "🗒️"
    "tip" -> "💡"
    "warning" -> "⚠️"
    "instructions" -> "📖"
    _ -> "⚠️"
  }
}

fn choose_callout_to_render(
  cache: Cache,
  doc: Document,
  blocks: List(Block),
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  case blocks {
    [Paragraph(_, inlines), ..blocks_tail] ->
      case inlines {
        [Text("["), Text(_), Text("]"), Text("-" <> foldable_title1), ..inlines] ->
          html.details(
            [],
            [
              html.summary(
                [],
                [
                  html.text(foldable_title1),
                ]
                  |> list.append(
                    list.map(inlines, inline_to_lustre(cache, doc, _)),
                  ),
              ),
            ]
              |> list.append(
                list.map(blocks_tail, block_to_lustre(
                  cache,
                  doc,
                  _,
                  Loose,
                  syntax_highlighter,
                )),
              ),
          )
        [Text("["), Text("!" <> callout_type), Text("]"), ..] ->
          html.blockquote(
            [attribute.class("alert alert-" <> callout_type)],
            [
              html.p([attribute.class("alert-heading")], [
                html.text(emojify(callout_type) <> " "),
                html.strong([], [html.text(callout_type |> string.capitalise)]),
              ]),
            ]
              |> list.append(
                list.map(blocks_tail, block_to_lustre(
                  cache,
                  doc,
                  _,
                  Loose,
                  syntax_highlighter,
                )),
              ),
          )
        _ -> element.none()
      }
    _ ->
      html.blockquote(
        [],
        list.map(blocks, block_to_lustre(
          cache,
          doc,
          _,
          Loose,
          syntax_highlighter,
        )),
      )
  }
}

fn paragraph_to_lustre(
  cache: Cache,
  doc: Document,
  text: List(Inline),
  pack: ListPack,
) -> Element(_) {
  let text =
    text
    |> trim_around_newlines(cache, _)
    |> escape_text(cache, _)
    |> inlines_to_lustre(cache, doc, _)
  case pack {
    Tight -> element.fragment(text)
    Loose -> html.p([], text)
  }
}

fn trim_around_newlines(cache: Cache, inlines: List(Inline)) -> List(Inline) {
  list.map_fold(inlines, SoftBreak, fn(acc, inline) {
    case acc, inline {
      SoftBreak, Text(text) -> #(
        inline,
        Text(regexp.replace(cache.trim_start, text, "")),
      )
      HardBreak, Text(text) -> #(
        inline,
        Text(regexp.replace(cache.trim_start, text, "")),
      )
      _, _ -> #(inline, inline)
    }
  }).1
}

fn escape_text(cache: Cache, inlines: List(Inline)) -> List(Inline) {
  list.map(inlines, fn(inline) {
    case inline {
      Text(text) ->
        text
        //|> escapes.html_escape(cache.entities, cache.html)
        |> handle_emoji_shortcodes(cache, _)
        |> Text
      _ -> inline
    }
  })
}

fn trim_lines(cache: Cache, para: String) -> String {
  // trim line starts and endings but not inside tags...
  let para = regexp.replace(cache.trim_end, para, "")
  let para = regexp.replace(cache.trim_start, para, "")
  para
}

fn codeblock_to_lustre(
  _: Cache,
  lang: Option(String),
  text: String,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> Element(_) {
  // html.pre([], [
  //   html.code(maybe_lang(cache, lang), [
  //     element.text(text),
  //   ]),
  // ])
  let render_function = glimra.codeblock_renderer(syntax_highlighter)
  render_function(dict.new(), lang, text)
}

// fn maybe_lang(cache: Cache, lang: Option(String)) {
//   case lang {
//     Some(lang) -> {
//       let #(lang, _, _) = splitter.split(cache.hspaces, lang)
//       use <- guard(lang == "", [])
//       [
//         attribute.class(
//           "language-"
//           <> {
//             lang
//             |> escapes.unescape(cache.esc)
//           },
//         ),
//       ]
//     }
//     None -> []
//   }
// }

fn heading_to_lustre(
  cache: Cache,
  doc: Document,
  level: Int,
  id: String,
  text: List(Inline),
) -> Element(_) {
  let attrs = case id {
    "" -> []
    _ -> [attribute.id(id)]
  }
  let text = text |> escape_text(cache, _) |> inlines_to_lustre(cache, doc, _)
  case level {
    1 -> html.h1(attrs, text)
    2 -> html.h2(attrs, text)
    3 -> html.h3(attrs, text)
    4 -> html.h4(attrs, text)
    5 -> html.h5(attrs, text)
    6 -> html.h6(attrs, text)
    _ -> panic as { "invalid header level " <> int.to_string(level) }
  }
}

fn thematic_break_to_lustre(_doc: Document) -> Element(_) {
  html.hr([])
}

fn inline_to_lustre(cache: Cache, doc: Document, inline: Inline) -> Element(_) {
  case inline {
    Checkbox(checked) -> checkbox_to_lustre(checked)
    CodeSpan(text) -> codespan_to_lustre(doc, text)
    Emphasis(inlines) -> em_to_lustre(cache, doc, inlines)
    Strong(inlines) -> strong_to_lustre(cache, doc, inlines)
    Strikethrough(inlines) -> strikethrough_to_lustre(cache, doc, inlines)
    Highlight(inlines) -> highlight_to_lustre(cache, doc, inlines)
    RefLink(text, label) -> reflink_to_lustre(cache, doc, text, label)
    FullLink(text, data) -> link_to_lustre(cache, doc, text, data)
    Footnote(num, label) -> footnote_to_lustre(doc, num, label)
    InlineFootnote(num, text) -> inline_footnote_to_lustre(doc, num, text)
    RefImage(text, label) -> refimage_to_lustre(cache, doc, text, label)
    FullImage(text, data) -> image_to_lustre(cache, text, data.dest, data.title)
    Autolink(uri, text) -> autolink_to_lustre(cache, uri, text)
    EmailAutolink(mail) -> email_autolink_to_lustre(mail)
    InlineHtml(tag, attrs, children) ->
      inline_html_to_lustre(cache, doc, tag, attrs, children)
    HardBreak -> hardbreak_to_lustre(doc)
    SoftBreak -> softbreak_to_lustre(doc)
    Text(text) -> element.text(text)
    RawHtml(_text) -> element.none()
    Delim(style, len, ..) -> element.text(string.repeat(style, len))
  }
}

fn inlines_to_lustre(
  cache: Cache,
  doc: Document,
  inlines: List(Inline),
) -> List(Element(_)) {
  list.map(inlines, inline_to_lustre(cache, doc, _))
}

fn inlines_to_attr(cache: Cache, inlines: List(Inline)) -> String {
  string.join(
    list.map(inlines, fn(inline) {
      case inline {
        Checkbox(..) -> ""
        CodeSpan(text) -> text
        Emphasis(inlines) -> inlines_to_attr(cache, inlines)
        Strong(inlines) -> inlines_to_attr(cache, inlines)
        Strikethrough(inlines) -> inlines_to_attr(cache, inlines)
        Highlight(inlines) -> inlines_to_attr(cache, inlines)
        RefLink(text, ..) -> inlines_to_attr(cache, text)
        FullLink(text, ..) -> inlines_to_attr(cache, text)
        Footnote(_num, label) -> label
        InlineFootnote(_num, text) -> inlines_to_attr(cache, text)
        RefImage(text, ..) -> inlines_to_attr(cache, text)
        FullImage(text, ..) -> inlines_to_attr(cache, text)
        Autolink(..) -> ""
        EmailAutolink(..) -> ""
        InlineHtml(..) -> ""
        HardBreak -> ""
        SoftBreak -> ""
        Text(text) -> text
        RawHtml(text) -> text |> trim_lines(cache, _)
        Delim(style, len, ..) -> string.repeat(style, len)
      }
    }),
    "",
  )
}

fn softbreak_to_lustre(_doc: Document) -> Element(_) {
  element.text("\n")
}

fn hardbreak_to_lustre(_doc: Document) -> Element(_) {
  html.br([])
}

fn checkbox_to_lustre(checked: Bool) -> Element(_) {
  let attrs = case checked {
    True -> [
      attribute.checked(True),
      attribute.disabled(True),
      attribute.type_("checkbox"),
    ]
    False -> [attribute.disabled(True), attribute.type_("checkbox")]
  }
  html.input(attrs)
}

fn inline_html_to_lustre(
  cache: Cache,
  doc: Document,
  tag: String,
  attrs: dict.Dict(String, String),
  children: List(Inline),
) -> Element(_) {
  element.element(
    tag,
    attrs |> dict.to_list |> list_to_attrs,
    inlines_to_lustre(cache, doc, children),
  )
}

fn list_to_attrs(
  list: List(#(String, String)),
) -> List(attribute.Attribute(msg)) {
  list.map(list, fn(pair) { attribute.attribute(pair.0, pair.1) })
}

fn encode_segment(_cache: Cache, segment: String) -> String {
  segment
  |> uri.percent_encode
}

fn normalize_path(cache: Cache, path: String) -> String {
  case string.split(path, "/") {
    [] -> uri.percent_encode(path)
    [base] ->
      case string.split_once(base, ":") {
        Ok(#(host, port)) -> uri.percent_encode(host) <> ":" <> port
        Error(_) -> base |> uri.percent_encode
      }
    [base, ..segments] -> {
      let base = case string.split_once(base, ":") {
        Ok(#(host, port)) -> uri.percent_encode(host) <> ":" <> port
        Error(_) -> uri.percent_encode(base)
      }
      let segments =
        string.join(list.map(segments, encode_segment(cache, _)), "/")
      base <> "/" <> segments
    }
  }
}

fn normalize_params(params: String) -> String {
  let paramlist =
    list.map(string.split(params, "&"), fn(p) {
      result.unwrap(string.split_once(p, "="), #(p, ""))
    })
  let params =
    list.map(paramlist, fn(p) {
      case p.1 {
        "" -> p.0
        _ -> p.0 <> "=" <> uri.percent_encode(p.1)
      }
    })
  string.join(params, "&")
}

fn normalize_uri(cache: Cache, uri: String) -> String {
  let schemesplitter = cache.scheme
  let querysplitter = cache.query
  let #(scheme, colon, rest) = splitter.split(schemesplitter, uri)
  let #(scheme, rest) = case colon {
    "" -> #("", scheme)
    _ -> #(scheme, rest)
  }
  let #(path, question, params) = splitter.split(querysplitter, rest)
  let path = case scheme {
    "mailto" ->
      case string.split_once(path, "@") {
        Ok(#(head, tail)) ->
          uri.percent_encode(head) <> "@" <> uri.percent_encode(tail)
        Error(_) -> uri.percent_encode(path)
      }
    "http" | "https" | "" ->
      case string.split_once(path, "#") {
        Ok(#(path, fragment)) ->
          normalize_path(cache, path) <> "#" <> uri.percent_encode(fragment)
        Error(_) -> normalize_path(cache, path)
      }
    _ -> path
  }
  let params = case question {
    "?" ->
      case string.split_once(params, "#") {
        Ok(#(params, fragment)) ->
          normalize_params(params) <> "#" <> uri.percent_encode(fragment)
        Error(_) -> normalize_params(params)
      }
    _ -> ""
  }
  let uri = string.join([scheme, colon, path, question, params], "")
  uri
}

fn autolink_to_lustre(
  cache: Cache,
  uri: String,
  text: Option(String),
) -> Element(_) {
  let href = uri |> trim_lines(cache, _) |> normalize_uri(cache, _)
  html.a([attribute.href(href)], [
    element.text(option.unwrap(text, uri)),
  ])
}

fn email_autolink_to_lustre(mail: String) -> Element(_) {
  html.a([attribute.href("mailto:" <> mail)], [element.text(mail)])
}

fn refimage_to_lustre(
  cache: Cache,
  doc: Document,
  text: List(Inline),
  label: String,
) -> Element(_) {
  case dict.get(doc.links, label) {
    Ok(link) -> image_to_lustre(cache, text, link.dest, link.title)
    Error(_) -> image_to_lustre(cache, text, Absolute(""), None)
  }
}

fn image_to_lustre(
  cache: Cache,
  text: List(Inline),
  dest: Destination,
  title: Option(String),
) -> Element(_) {
  let attrs = []
  let attrs = case title {
    Some(title) -> [attribute.title(title), ..attrs]
    None -> attrs
  }
  let attrs = case text {
    [] -> [attribute.alt(""), ..attrs]
    _ -> [attribute.alt(inlines_to_attr(cache, text)), ..attrs]
  }
  let attrs = [attribute.src(dest_to_string(cache, dest)), ..attrs]
  html.img(attrs)
}

fn normalize_dest(cache: Cache, d: String) {
  escapes.entityrefs(d, cache.entities, cache.amp, cache.semi)
  |> uri.percent_decode
  |> result.unwrap(d)
  |> normalize_uri(cache, _)
}

fn dest_to_string(cache: Cache, dest: Destination) -> String {
  case dest {
    Absolute(uri) -> uri |> normalize_dest(cache, _)
    Relative(uri) -> uri |> normalize_dest(cache, _)
    Anchor(id) -> "#" <> uri.percent_encode(id)
  }
}

fn footnote_to_lustre(_doc: Document, num: Int, label: String) -> Element(_) {
  html.sup([attribute.class("footnote-ref")], [
    html.a(
      [
        attribute.attribute("id", "fnref:" <> int.to_string(num)),
        attribute.attribute("href", "#fn:" <> int.to_string(num)),
        attribute.data("footnote-ref", ""),
        attribute.aria_describedby("footnotes"),
      ],
      [element.text(label)],
    ),
  ])
}

fn inline_footnote_to_lustre(
  doc: Document,
  num: Int,
  _text: List(Inline),
) -> Element(_) {
  // we don't use the text here, but in the footnote list pass we will
  footnote_to_lustre(doc, num, int.to_string(num))
}

fn reflink_to_lustre(
  cache: Cache,
  doc: Document,
  text: List(Inline),
  label: String,
) -> Element(_) {
  case dict.get(doc.links, label) {
    Ok(link) -> link_to_lustre(cache, doc, text, link)
    Error(_) -> link_to_lustre(cache, doc, text, LinkData(Absolute(""), None))
  }
}

fn link_to_lustre(
  cache: Cache,
  doc: Document,
  text: List(Inline),
  data: LinkData,
) -> Element(_) {
  let attrs = [
    attribute.href(dest_to_string(cache, data.dest)),
    ..{
      case data.title {
        Some(title) -> [
          attribute.title(title),
        ]
        None -> []
      }
    }
  ]
  html.a(attrs, inlines_to_lustre(cache, doc, text))
}

fn strong_to_lustre(
  cache: Cache,
  doc: Document,
  inlines: List(Inline),
) -> Element(_) {
  html.strong(
    [],
    inlines |> escape_text(cache, _) |> inlines_to_lustre(cache, doc, _),
  )
}

fn strikethrough_to_lustre(
  cache: Cache,
  doc: Document,
  inlines: List(Inline),
) -> Element(_) {
  html.del(
    [],
    inlines |> escape_text(cache, _) |> inlines_to_lustre(cache, doc, _),
  )
}

fn highlight_to_lustre(
  cache: Cache,
  doc: Document,
  inlines: List(Inline),
) -> Element(_) {
  html.mark(
    [],
    inlines |> escape_text(cache, _) |> inlines_to_lustre(cache, doc, _),
  )
}

fn em_to_lustre(
  cache: Cache,
  doc: Document,
  inlines: List(Inline),
) -> Element(_) {
  html.em(
    [],
    inlines |> escape_text(cache, _) |> inlines_to_lustre(cache, doc, _),
  )
}

fn codespan_to_lustre(_doc: Document, text: String) -> Element(_) {
  html.code([], [element.text(text)])
}

fn handle_emoji_shortcodes(cache: Cache, text: String) -> String {
  do_handle_emoji_shortcodes(cache, text, "")
}

fn do_handle_emoji_shortcodes(cache: Cache, text: String, acc: String) -> String {
  let #(l, s, r) = splitter.split(cache.colon, text)
  let body = acc <> l
  case s {
    ":" ->
      case cache.ends_with_ws(body) || cache.ends_with_p(body) {
        True -> {
          let #(code, s2, r2) = splitter.split(cache.colon, r)
          case s2 {
            ":" ->
              case emojis.get(cache.emojis, code) {
                Ok(emoji) ->
                  do_handle_emoji_shortcodes(cache, r2, body <> emoji)
                Error(Nil) ->
                  do_handle_emoji_shortcodes(cache, s2 <> r2, body <> s <> code)
              }
            "" -> body <> s <> code
            _ -> panic as "unreachable"
          }
        }
        False -> do_handle_emoji_shortcodes(cache, r, body <> s)
      }
    "" -> body
    _ -> panic as "unreachable"
  }
}
