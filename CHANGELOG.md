# v0.3.6 2021-03-10

- Synchronize access with Mutex
- Add key_resolver
- Inherit options set through accessors

# v0.3.5 2020-12-23

- Allow to inherit options in nested registries

# v0.3.5 2020-12-04

- Allow patterns as keys

# v0.3.4 2020-12-04

- Bring back Singleton
- Fix mistakes in readme

# v0.3.3 2020-11-24

- Fix: Pass key to resolver instead of value 

# v0.3.2 2020-09-29

- Fix interface definition

# v0.3.1 2020-09-23

- Allow to define custom accessors for registries

# v0.3.0 2020-09-10

### Breaking Changes
 
- Toggled interface for resolve(!) and register(!)
- Allow to register values in nested registries
- Rename nested method into level
- Provide registry readers
- Remove Singleton extension
- Allow to resolve paths
- Pass key to default block when it takes an argument

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
