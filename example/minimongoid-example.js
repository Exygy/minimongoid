if (Meteor.isClient) {
  Meteor.subscribe('userData');
  Meteor.subscribe('recipes');

  Template.main.currentUserId = function () {
    return Meteor.userId();
  };

  Template.recipes.my_recipes = function () {
    return User.current().r('recipes');
  };
  Template.recipes.events({
    'click #recipe-save' : function(e, t) {
      e.preventDefault();
      recipe = Recipe.create({
        user_id: Meteor.userId(),
        name:    $(t.find('#recipe-name')).val()
      });
      if (Recipe.errors) {
        $(t.find('#recipe-form')).addClass('error');
        $(t.find('#recipe-form .help-inline')).html(Recipe.error_message());
      }
    }
  });


  Template.friends.other_users = function () {
    return User.where({_id: {$ne: Meteor.userId()} }, {fields: {username: 1}});
  };
  Template.friends.events({
    'click #friends a' : function(e, t) {
      e.preventDefault();
      var attr = {friend_ids: this.id};
      if (User.current().friendsWith(this.id)) {
        User.current().pull(attr);
      } else {
        User.current().push(attr);
      }
      // $('#friend-nav').tab('show');
    }    
  });


  Template.friends_recipes.recipes = function () {
    var recipes = _.reduceRight(User.current().r('friends'), function(a, b) { return a.concat(b.r('recipes')); }, []);
    return recipes;
  };


  Template.recipe.events({
    'click .ingredient-save' : function(e, t) {
      e.preventDefault();
      var ingredient = {name: $(t.find('.ingredient-name')).val()};
      var quantity = $(t.find('.ingredient-quantity')).val(); 
      if (quantity) ingredient.quantity = parseInt(quantity);
      // this = this Recipe
      this.push({
        ingredients: ingredient
      });
    },
    'click .del' : function(e, t) {
      e.preventDefault();
      var recipe = this;
      $(t.firstNode).fadeOut(function() {
        recipe.destroy();
      })
    }
  });

  Template.ingredient.events({
    'click .del' : function(e, t) {
      e.preventDefault();
      this.recipe.pull({
        ingredients: {name: this.name}
      });
    }
  });


}

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup

    // back to the basics, delete everything
    // User.destroyAll();
    // Recipe.destroyAll();

  });

  Meteor.publish('userData', function() {
    return User.find({}, {
      fields: {
        username: 1,
        friend_ids: 1
      }
    });
  });
  Meteor.publish('recipes', function() {
    return Recipe.find();
  });


  Meteor.users.allow({
    update: function(user_id, doc, fields, modifier) {
      if (doc._id !== Meteor.userId()) {
        return false;
      } else {
        return true; 
      }
    }
  });

  Recipe._collection.allow({
    insert: function(user_id, doc) {
      return user_id && doc.user_id == user_id;
    },
    update: function(user_id, doc, fields, modifier) {
      return user_id && doc.user_id == user_id;
    },
    remove: function(user_id, doc) {
      return user_id && doc.user_id == user_id;
    }    
  })

  // Meteor.methods({
  //   add_friend: function() {}
  // })



  Accounts.onCreateUser(function(options, user) {
    // give the user a "username" based on the initial part of their email address
    user.username = User.init(user).email().split('@')[0];
    if (options.profile) user.profile = options.profile;
    return user;
  });


}
