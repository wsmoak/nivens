  angular.module('nivensApp',[])
    .controller('MainCtrl', ['$http', function($http) {
      
      var self = this;
      
      self.rabbits = [];
      self.rabbit = {};
      self.card = {};
      self.currentTab = 'home';
      
      var fetchRabbits = function() {
        return $http.get('/api/rabbit').then(
          function(response){
            self.rabbits = response.data;
          }, 
          function(errResponse) {
            console.error('Error while fetching rabbits');
          }
        );
      };
      
      fetchRabbits();
      
      self.add = function() {
        $http.post('/api/rabbit', self.rabbit)
          .then(fetchRabbits)
          .then( function(response) {
            self.rabbit = {};
            self.currentTab = 'rabbits';
          });
      };

      self.purchase = function() {
        console.log( "purchase");
        Stripe.setPublishableKey('pk_test_4ZzD3dUkMiTnVLpwymISz9Uf');
        Stripe.card.createToken({
          number: self.card.number,
          cvc: self.card.cvc,
          exp_month: self.card.exp_month,
          exp_year: self.card.exp_year
        }, self.stripeResponseHandler);
      };
      
      self.stripeResponseHandler = function(status, response) {
        console.log( "stripe response handler");
        console.log( status );
        console.log( response );

        if (status == 200 ) {
          $http.post('/rabbit/purchase', response )
          .then( function(response) {
            console.log("after post to purchase");
            console.log(response);
            self.card = {};
          });
        } else {
          console.log( "problem with tokenizing");
        }

      }

    }]);
