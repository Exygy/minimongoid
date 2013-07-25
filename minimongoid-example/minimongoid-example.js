if (Meteor.isClient) {
  Meteor.subscribe('userData');

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
      // console.log(this)
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
    // User.destroyAll();
    // Recipe.destroyAll();

    Meteor.users.update('7R5hDc8tEENKnprC5', { '$addToSet': { friend_ids: 'RibuoMwzYqoScQe9F' } })

  });

  Meteor.publish('userData', function() {
    return User.find({}, {
      fields: {
        username: 1,
        friend_ids: 1
      }
    });
  });


  Meteor.users.allow({
    update: function(user_id, doc, fields, modifier) {
      console.log(doc)
      if (doc._id !== Meteor.userId()) {
        return false;
      } else {
        console.log('allowed', modifier)
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
    // We still want the default hook's 'profile' behavior.
    user.username = User.init(user).email().split('@')[0];
    console.log(user);
    if (options.profile)
      user.profile = options.profile;
    return user;
  });


}
