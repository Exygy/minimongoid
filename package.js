Package.describe({
  summary: "Mongoid inspired model architecture",
  version: "0.9.5",
  git: "https://github.com/Exygy/minimongoid.git"
});

Package.on_use(function (api) {
  api.versionsFrom("METEOR@0.9.0");
  var both = ['client', 'server'];
  api.use(['underscore', "mrt:underscore-string-latest@2.3.3", 'coffeescript'], both);
  files = [
    'lib/relation.coffee',
    'lib/has_many_relation.coffee',
    'lib/has_and_belongs_to_many_relation.coffee',
    'lib/minimongoid.coffee'
  ];
  api.add_files(files, both);
});

Package.on_test(function (api) {
  var both = ['client', 'server'];
  api.use(["kaptron:minimongoid", 'tinytest', 'coffeescript'], both);
  api.add_files('tests/models.coffee', both);
  api.add_files('tests/server_tests.coffee', ['server']);
  api.add_files('tests/model_tests.coffee', both);
});
