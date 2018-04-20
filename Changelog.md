# Change Log
All notable changes to this project will be documented in this file.

Please group changes into `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`
and `Security` as described in [Keep a Changelog](http://keepachangelog.com/),
taking the above order into account.

## [Unreleased]


________________________________________________________________________________

## [0.2.4] - 2018-04-20

### Added
- this Changelog

### Changed
- yield `zone` to block in `Teasy.with_zone`
- always use `Teasy.with_zone` internally when looking up the
  `TZInfo::Timezone`. That way one could support other time zone names than the
  TZInfo Identifier by making `Teasy.with_zone` convert those
