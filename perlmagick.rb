class Perlmagick < Formula
  desc "ImageMagick built with Perl support (PerlMagick)"
  homepage "https://imagemagick.org"
  url "https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-35/ImageMagick-7.1.2-35.7z"
  sha256 "1d95f7d0ed11e91a3ee9e3042a8e248cb88c666dd9256ab14cc871b1f73138fd"
  license "ImageMagick"
  head "https://github.com/ImageMagick/ImageMagick.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+-\d+)$/i)
    strategy :github_releases
  end

  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "ghostscript"
  depends_on "glib"
  depends_on "jpeg-turbo"
  depends_on "jpeg-xl"
  depends_on "libheif"
  depends_on "liblqr"
  depends_on "libpng"
  depends_on "libraw"
  depends_on "librsvg"
  depends_on "libtiff"
  depends_on "libtool"
  depends_on "libultrahdr"
  depends_on "libzip"
  depends_on "little-cms2"
  depends_on "openexr"
  depends_on "openjpeg"
  depends_on "perl"
  depends_on "webp"
  depends_on "xz"

  uses_from_macos "bzip2"
  uses_from_macos "libxml2"

  on_macos do
    depends_on "gdk-pixbuf"
    depends_on "gettext"
    depends_on "imath"
    depends_on "libomp"
  end

  on_linux do
    depends_on "libx11"
    depends_on "libxext"
    depends_on "zlib-ng-compat"
  end

  conflicts_with "imagemagick", because: "both install the same ImageMagick binaries, libraries and headers"

  skip_clean :la

  deny_network_access!

  def perl
    formula_opt_bin("perl")/"perl"
  end

  def perl_config(key)
    Utils.safe_popen_read(perl, "-MConfig", "-e", "print $Config{#{key}}")
  end

  def perl_site_lib
    lib/"perl5/site_perl"/File.basename(perl_config("sitelib"))
  end

  def install
    # Avoid references to shim
    inreplace Dir["**/*-config.in"], "@PKG_CONFIG@", formula_opt_bin("pkg-config")/"pkg-config"
    # versioned stuff in main tree is pointless for us
    inreplace "configure", "${PACKAGE_NAME}-${PACKAGE_BASE_VERSION}", "${PACKAGE_NAME}"

    perl_options = %W[
      INSTALLDIRS=site
      INSTALLSITELIB=#{perl_site_lib}
      INSTALLSITEARCH=#{perl_site_lib}/#{perl_config("archname")}
      INSTALLSITEMAN3DIR=#{man3}
      NO_PERLLOCAL=1
      NO_PACKLIST=1
    ]

    args = [
      "--enable-osx-universal-binary=no",
      "--disable-silent-rules",
      "--disable-opencl",
      "--enable-shared",
      "--enable-static",
      "--with-freetype=yes",
      "--with-rsvg=yes",
      "--with-gvc=no",
      "--with-modules",
      "--with-openjp2",
      "--with-openexr",
      "--with-webp=yes",
      "--with-heic=yes",
      "--with-perl=#{perl}",
      "--with-perl-options=#{perl_options.join(" ")}",
      "--with-raw=yes",
      "--with-uhdr=yes",
      "--with-zip=yes",
      "--with-gslib",
      "--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts",
      "--with-lqr",
      "--without-djvu",
      "--without-fftw",
      "--without-pango",
      "--without-wmf",
      "--enable-openmp",
    ]
    if OS.mac?
      args += [
        "--without-x",
        # Work around "checking for clang option to support OpenMP... unsupported"
        "ac_cv_prog_c_openmp=-Xpreprocessor -fopenmp",
        "ac_cv_prog_cxx_openmp=-Xpreprocessor -fopenmp",
        "LDFLAGS=-lomp -lz",
      ]
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  def caveats; <<~EOS
    This module is built for Homebrew's perl (#{perl}), it probably cannot be
    loaded by other perls.
  EOS
  end

  test do
    assert_match "PNG", shell_output("#{bin}/identify #{test_fixtures("test.png")}")

    # Check support for recommended features and delegates.
    features = shell_output("#{bin}/magick -version")
    %w[Modules freetype heic jpeg png raw rsvg tiff].each do |feature|
      assert_match feature, features
    end

    # Check support for a few specific image formats, mostly to ensure LibRaw linked correctly.
    formats = shell_output("#{bin}/magick -list format")
    ["AVIF  HEIC      rw+", "ARW  DNG       r--", "DNG  DNG       r--"].each do |format|
      assert_match format, formats
    end

    # Check that PerlMagick can be loaded and can read and write an image.
    (testpath/"test.pl").write <<~PERL
      use strict;
      use warnings;
      use Image::Magick;

      my $image = Image::Magick->new;
      my $error = $image->Read($ARGV[0]);
      die $error if $error;
      $error = $image->Write("test.jpg");
      die $error if $error;
      print join("x", $image->Get("width", "height")), "\n";
    PERL
    assert_match(/^\d+x\d+$/, shell_output("#{perl} -Mlib=#{perl_site_lib} test.pl #{test_fixtures("test.png")}"))
    assert_path_exists testpath/"test.jpg"
  end
end
