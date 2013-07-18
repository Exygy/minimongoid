Package.describe({
  summary: "Mongoid inspired model architecture"
});

Package.on_use(function (api) {
  var both = ['client', 'server'];
  api.use(['underscore', 'underscore-string', 'underscore-inflection', 'coffeescript'], both);
  api.add_files(['lib/minimongoid.coffee'], both);
});

Package.on_test(function (api) {
  var both = ['client', 'server'];
  api.use(['minimongoid', 'tinytest'], both);
  api.add_files('tests/models.coffee', both);
  api.add_files('tests/server_tests.coffee', ['server']);
  api.add_files('tests/model_tests.coffee', both);
});