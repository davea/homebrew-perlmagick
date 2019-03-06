# homebrew-perlmagick

Homebrew [removed Perl support](https://github.com/Homebrew/homebrew-core/commit/f53609a6c42ddf2d27611eb02920e77452cd0ccb) from their `imagemagick` formula.

This tap provides a new `perlmagick` formula that builds Imagemagick with Perl support again.

## Usage

```bash
$ brew tap davea/perlmagick
$ brew install perlmagick
```

## Caveats

 - No bottles, so expect a wait whilst it builds (just like before when using the `--with-perl` option)
 - This is likely to only be sporadically updated so don't rely on it to be up to date with any security issues.
