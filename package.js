Package.describe({
  summary: "Mongoid inspired model architecture"
});

Package.on_use(function (api) {
  var both = ['client', 'server'];
  api.use(['underscore', 'underscore-string-latest', 'coffeescript'], both);
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
  api.use(['minimongoid', 'tinytest'], both);
  api.add_files('tests/models.coffee', both);
  api.add_files('tests/server_tests.coffee', ['server']);
  api.add_files('tests/model_tests.coffee', both);
});
