# pablo.town

My personal website meant to share blog posts and informations about me, my projects and maybe more.

## Tech stack

This is a static site built with [lustre/ssg](https://github.com/lustre-labs/ssg) in [gleam](https://gleam.run). Most of the content is defined within the code, or with text/markdown files.

The style is made in pure css (see [helpful resources](#helpful-resources)).

For code blocks syntax highlighting I used [glimra](https://github.com/ollema/glimra) to generate a css stylesheet that I slightly modified to make it compatible with light/dark themes using the `light-dark` css function.

Speaking of themes, I used the [catppuccin](https://catppuccin.com/) color themes :
  - catppuccin latte for the light theme
  - catppuccin mocha for the dark theme

## Development

```sh
gleam test  # Run the tests
gleam run -b build   # Build the site
```

## Helpful resource 

- [You no longer need JavaScript](https://lyra.horse/blog/2025/08/you-dont-need-js/) by [lyra rebane](https://lyra.horse/), which made me realize css is now way more powerful and less of a headash than what I thought.
