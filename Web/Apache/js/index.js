$(() => {
    Vue.component('line-chart', {
        extends: VueChartJs.Line,
        props: ['labels', 'data'],
        methods: {
            renderLineChart: function() {
                this.renderChart({
                    labels: this.labels,//['January', 'February', 'March', 'April', 'May', 'June', 'July'],
                    datasets: this.data,
                }, {responsive: true, maintainAspectRatio: false})
            }
        },
        watch: {
            data: function() {
                this.renderLineChart()
            }
        },
        mounted () {
            this.renderLineChart()
       }
    })
    var app = new Vue({
        el: '#app',
        vuetify: new Vuetify(),
        components: {
            vuejsDatepicker,
        },
        data: function() {return {
            strBaseURL: document.location.origin,
            intStart: moment(new Date('4/7/2020')).unix(), // 1586221200,
            intEnd: moment(new Date('4/8/2020')).unix(),// 1586241900,
            blnLoading: true,
            blnSuccessOnly: false,
            blnAttendenceChartHeaderFixed: true,
            dense: true,
            fixedHeader: true,
            singleExpand: false,
            height: 500,
            logs: [],
            expanded: [],
            headers: [
                { text: "Start", value: "start"},
                { text: "Duration", value: "duration"},
                { text: "Fight Name", value: "fight"},
                { text: "", value: "data-table-expand"},
            ],
            arrDatesWithPulls: [],
            arrAttendenceHeaders: [],
            arrAttendenceData: [],
            arrAttendenceProfessionLookup: [],
            arrAttendenceRoleLookup: [],
            arrAttendenceSummary: [],
            arrAttendenceSummaryHeaders: [
                { text: "Account" , value: "account" },
                { text: "Date" , value: "date" },
                { text: "Week Day" , value: "dayOfWeek" },
            ],
        }},
        computed: {
            dpsChartLabels: function() {
                let self = this
                return this.logs.filter((log) => {
                    return log.json !== null && (!self.blnSuccessOnly || log.json.success)
                }).map((log) => {
                    return log.json.fightName
                })
            },
            dpsChartData: function() {
                let self = this;
                var objChartData = this.logs.filter((log) => {
                    return log.json !== null && (!self.blnSuccessOnly || log.json.success)
                }).map((log) => { 
                    return log.json.players.map((player) => {
                        return player.account
                    })
                })
                .flat('Infinity')
                .filter((item, index, array) => {
                    return array.indexOf(item) === index
                }).concat(['Group DPS'])
                .map((account) => {
                    return {
                        label: account,
                        // backgroundColor: ???
                        lineTension: 0,
                        data: self.logs.filter((log) => {
                            return log.json !== null
                        }).map((log) => {
                            if(account==='Group DPS'){
                                return log.json.players.map((player) => {return player.dpsTargets[0][0].dps}).reduce((prev, curr) => {return prev + curr}, 0)
                            }
                            else {
                                var player = log.json.players.filter((player) => {return player.account==account})
                                if(player.length==0) return null
                                if(player.length>1) return undefined
                                return player[0].dpsTargets[0][0].dps
                            }
                        })
                    }
                })
                return objChartData
            },

            burnChartLabels: function() {
                let self = this
                // return ['January', 'February', 'March', 'April', 'May', 'June', 'July']
                return this.logs.filter((log) => {
                    return log.json !== null && (!self.blnSuccessOnly || log.json.success)
                }).map((log) => {
                    return log.json.fightName
                })
            },
            burnChartData: function() {
                let self = this
                return  [{
                    label: 'Percent Burned',
                    backgroundColor: '#f87979',
                    lineTension: 0,
                    // data: [40, 39, 10, 40, 39, 80, 40]
                    data: this.logs.filter((log) => {
                        return log.json !== null && (!self.blnSuccessOnly || log.json.success)
                    }).map((log) => {
                        return log.json.targets[0].healthPercentBurned
                    })
                }]
            },
            processedArrAttendenceData: function() {
                let self = this
                return this.arrAttendenceData
                    .filter((data) => {
                        return !self.blnSuccessOnly || self.logs
                                .filter((log) => {return log.id===data.Log})
                                .reduce((prev, curr) => {return curr.json;}, {success: undefined}).success
                    })
                    .map((data) => {
                    return Object.keys(data)
                        .filter((key) => {return ['Log'].indexOf(key) === -1})
                        .map((key) => {
                            switch(key) {
                                case "Start":
                                    return [key, moment.unix(data[key]).format("MM-DD-YYYY HH:mm:ss")]
                                case "Boss":
                                    var objBoss = {name: data[key]}
                                    objBoss.strFile = self.logs
                                                        .filter((log) => {return log.id===data.Log})
                                                        .reduce((prev, curr) => {return curr}, {}).strFile
                                    return [key, objBoss]
                                default:
                                    var objPlayer = {blnPresent: (data[key]==1)?true:false}
                                    objPlayer.profession = self.arrAttendenceProfessionLookup
                                                            .filter((profession) => {return profession.Log==data.Log && profession.Account==key})
                                                            .reduce((prev, curr) => { return curr}, {})
                                    return [key, objPlayer]
                            }
                        })
                        .reduce((prev, curr) => {
                            prev[curr[0]] = curr[1]
                            return prev
                        }, {id: data.Log})
                })
            },
            filteredLogs: function() {
                let self = this
                return this.logs.filter((log) => {
                    return !self.blnSuccessOnly || (log.json!==null && log.json.success)
                })
            },
            filteredArrAttendenceHeaders: function() {
                let self = this
                return this.arrAttendenceHeaders
                        .concat([{text: "", value: "data-table-expand"}])
                        .filter((header) => {
                            switch(header.text) {
                                case "Log": return false;
                                default: return true;
                            }
                        })
                        .map((header) => {
                            if(header.text=="Start" || header.text=="Boss") header.fixed = true;
                            return header
                        })
            },
            processedArrAttendenceSummary: function() {
                return this.arrAttendenceSummary.map((value, index) => {
                    return {id: index, account: value.Account, date: value.Date, dayOfWeek: moment(new Date(value.Date)).format('dddd')}
                })
            },
        },
        methods: {
            fetchData: function() {
                let self = this
                self.blnLoading = true;
                fetch(self.strBaseURL + ":5000/vue?intStart=" + self.intStart + "&intEnd=" + self.intEnd)
                    .then((response) => {
                        return response.json()
                    })
                    .then((data) => {
                        self.logs = data[1].map((log) => {
                            return {
                                id: log.Log, 
                                // next: log.Next, 
                                unixStart: moment.unix(log.unixStart).format("MM-DD-YYYY HH:mm:ss"), 
                                json: JSON.parse(log.Json_Log),
                                strFile: "../reports/" + log.strFile,
                            }})

                        self.arrDatesWithPulls = data[0].map((date) => {
                            return {
                                date: date.Date
                            }})
                        
                        self.arrAttendenceHeaders = Object.keys(data[2][0]).map((header) => {return {text: header, value: header}})
                        self.arrAttendenceData = data[2]
                        self.arrAttendenceProfessionLookup = data[3]
                        self.arrAttendenceRoleLookup = data[4]
                        self.arrAttendenceSummary = data[5]

                        self.blnLoading = false;
                    })
            },
            strStart: function(intStart) {
                return moment.unix(intStart).format("MM-DD-YYYY HH:mm:ss")
            },
            updateStart: function(date) {
                this.intStart = moment(date).startOf('day').add(18, 'hours').unix()
                this.intEnd = moment(date).endOf('day').unix()
                this.fetchData()
                return
            },
            setiFrameHeight: function() {
                // console.log("setiFrameHeight", $("#dpsReport")[0].contentWindow.document)
                // console.log("setiFrameHeight", $("body", $($("#dpsReport")[0].contentWindow.document)).html())
                // console.log("setiFrameHeight", $("window", $("#dpsReport")[0].contentWindow.document).height());
            }
        },
        mounted: function() {
            this.fetchData()
        }
    })
});