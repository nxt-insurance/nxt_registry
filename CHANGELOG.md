# v0.3.0 2020-09-10

### Breaking Changes
 
- Toggled interface for resolve(!) and register(!)
- Allow to register values in nested registries
- Rename nested method into level
- Provide registry readers
- Remove Singleton extension
- Allow to resolve paths

[Compare v0.2.1...v0.3.0](https://github.com/nxt-insurance/nxt_registry/compare/v0.2.1...v0.3.0)

# v0.2.1 2020-08-14

### Fixed
 
- Fixed Registry#fetch to raise key error in case of missing key

[Compare v0.2.0...v0.2.1](https://github.com/nxt-insurance/nxt_registry/compare/v0.2.0...v0.2.1)


# v0.2.0 2020-07-24

### Added

- [internal] Added NxtRegistry::Singleton
- Added NxtRegistry::Singleton interface
- Make name optional and have object_id.to_s as default name 
- Fix readme

[Compare v0.1.5...v0.2.0](https://github.com/nxt-insurance/nxt_registry/compare/v0.1.5...v0.2.0)
