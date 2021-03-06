angular.module('nivensApp',[])
  .controller('MainCtrl', ['$http', 
    
    function($http) {
    
      var self = this;
    
      self.rabbits = [];
      self.rabbit = {};
      self.currentTab = 'home';
    
      var fetchRabbits = function() {
        return $http.get('/api/rabbit').then(
          function(response){
            self.rabbits = response.data;
            console.log("rabbits"+self.rabbits);
          }, 
          function(errResponse) {
            console.error('Error while fetching rabbits');
          }
        );
      };
      
      fetchRabbits();
      
      self.add = function() {
        console.log( self.rabbit);
        $http.post('/api/rabbit', self.rabbit)
          .then(fetchRabbits())
          .then( function(response) {
            self.rabbit = {};
            self.currentTab = 'rabbits';
          });
      };
      
    }

  ]);
