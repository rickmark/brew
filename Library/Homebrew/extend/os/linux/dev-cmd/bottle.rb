# typed: false
# frozen_string_literal: true

module Homebrew
  extend T::Sig

  module_function

  def setup_tar_and_args!(args, mtime)
    generic_setup_tar_and_args!(args, mtime)

    # Ensure tar is set up for reproducibility.
    # https://reproducible-builds.org/docs/archives/
    gnutar_args = [
      "--format", "pax", "--owner", "0", "--group", "0", "--sort", "name", "--mtime=#{mtime}",
      # Set exthdr names to exclude PID (for GNU tar <1.33). Also don't store atime and ctime.
      "--pax-option", "globexthdr.name=/GlobalHead.%n,exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime"
    ].freeze

    ["tar", gnutar_args].freeze
  end

  def formula_ignores(f)
    cellar_regex = Regexp.escape(HOMEBREW_CELLAR)
    prefix_regex = Regexp.escape(HOMEBREW_PREFIX)

    ignores = generic_formula_ignores(f)

    ignores << case f.name
    # On Linux, GCC installation can be moved so long as the whole directory tree is moved together:
    # https://gcc-help.gcc.gnu.narkive.com/GnwuCA7l/moving-gcc-from-the-installation-path-is-it-allowed.
    when Version.formula_optionally_versioned_regex(:gcc)
      Regexp.union(%r{#{cellar_regex}/gcc}, %r{#{prefix_regex}/opt/gcc})
    # binutils is relocatable for the same reason: https://github.com/Homebrew/brew/pull/11899#issuecomment-906804451.
    when Version.formula_optionally_versioned_regex(:binutils)
      %r{#{cellar_regex}/binutils}
    end

    ignores.compact
  end
end
