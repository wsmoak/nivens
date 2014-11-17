  angular.module('nivensApp',[])
    .controller('MainCtrl', ['$http', function($http) {
      
      console.log('MainCtrl has been created');
      
      var self = this;
      
      self.rabbits = [];
      self.rabbit = {};
      
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
        console.log('Submitted with', self.rabbit);
        $http.post('/api/rabbit', self.rabbit)
          .then(fetchRabbits)
          .then( function(response) {
            self.rabbit = {};
          });
      };
      
    }]);
