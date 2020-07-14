$(() => {
    var app = new Vue({
        el: '#app',
        vuetify: new Vuetify(),
        components: {
            vuejsDatepicker,
        },
        data: function() {return {
            strBaseURL: "http://localhost" // document.location.origin,
        }},
        computed: {
        },
        methods: {
            fetchData: function() {
                let self = this
                self.blnLoading = true;
                fetch(self.strBaseURL + ":5000/historicalRoles")
                    .then((response) => {
                        return response.json()
                    })
                    .then((data) => {
                        console.log("DATA", data)
                    })
            },
        },
        mounted: function() {
            this.fetchData()
        }
    })
})