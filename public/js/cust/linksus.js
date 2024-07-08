const { createApp, ref, onMounted, watch } = Vue;
const { useQuasar } = Quasar

const app = Vue.createApp({
  name: 'MyLayout',
  setup () {
    const leftDrawerOpen = ref(false)
    const isprocessing = ref(false)
    const client_file_ext = ref(null)
    const textext = ref("Escolha o arquivo do COE")
    const $q = useQuasar()
    const cruzamento = ref(null)
    const cruzamentos = ref([])
    const cruzado = ref(null)   

    const client_file1 = ref(null)
    const client_file2 = ref(null)   
    const modo_rev = ref(false)
    const textb1 = ref("Banco 1 não importado")
    const textb2 = ref("Banco 2 não importado")
    const bd = ref({b1: null, b2: null})
    const labelb1 = ref("Banco 1")
    const labelb2 = ref("Banco 2")
    const list_rel = ref([])
    const selrel = ref(null)
    const list_rel_avan = ref([])
    const selrel_avan = ref(null)
    const rel_avan = ref(false)

    const form_rev = ref({})
    const cor_rev = ref({})
    const max_rev = ref(0)
    const row_rev = ref(0)
    const textrel = ref('')
    const revisado = ref('')
    const par_rev = ref('')

    const update_model_bt = ref(false)

    const msg = ref('')
    const q_alert = ref(false)

    watch(cruzamento, (newValue, oldValue) => {
      axios.get('/get_bd', {params: {cruzamento: newValue}})
        .then((resp) => {
          console.log(resp)
          bd.value = resp.data.bd
          list_rel.value = resp.data.list_rel
        });
    });
    watch(bd, (value, oldValue) => {
      if (value.b1 != null) {
        cruzamento.value = value.crz_id
        textb1.value = `Foram importados ${value.b1_n} registros`;
        textb2.value = `Foram importados ${value.b2_n} registros`;
        labelb1.value = value.b1;
        labelb2.value = value.b2;

      }
    })

    watch(selrel, (value, oldValue) => {
      axios.get('/get_rel_avan', {params: {selrel: value}})
        .then((resp) => {
          list_rel_avan.value = resp.data.list_rel_avan
        });
    })

    watch(row_rev, (value, oldValue) => {
      if (value == 0) {
        return
      }
      axios.get('/change_rev', {params: {row_rev: value, max_rev: max_rev.value}})
        .then((resp) => {
          console.log(resp)
          form_rev.value = resp.data.form_rev
          cor_rev.value = resp.data.cor_rev
          par_rev.value = resp.data.par_rev
        });
    })


    watch(leftDrawerOpen, (value, oldValue) => {
      console.log('watch leftDrawerOpen')
      console.log(value)
    })



    function rel_nsus_covid_pos_Submit(evt) {    
      isprocessing.value = true               
      textext.value = "Aguarde";
      if (client_file_ext.value == null) {
        $q.notify({
          color: 'red-5',
          textColor: 'white',
          icon: 'warning',
          message: 'Você precisa escolher o arquivo do COE antes de prosseguir'
        });      
        isprocessing.value = false;
      } else {
        let notif = $q.notify({
          type: 'ongoing',     
          message: 'Enviado, aguarde'
        });
        //alert(this.client_file1);
        
        const formData = new FormData(evt.target);
        const data = [];

        axios.post('/rel_nsus_covid_pos',
          formData,
          {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
          }
        ).then(function(resp){  
          console.log(resp.data);
          isprocessing.value = false;
          textext.value = "Processamento concluído";
          msg.value = resp.data.msg2;
          q_alert.value = true;
          update_model_bt.value = true;          
                    
          notif({
            type: resp.data.cor,   
            message: resp.data.msg      
          });     

        })
        .catch(function(){  
          notif({
            type: 'negative',
            message: 'Algo deu errado'
          })
        });
      
      }
    }

    function rel_bt_pad() {
      isprocessing.value = true
      axios.get('/rel_bt_pad', {params:{cruzamento: cruzamento.value, selrel:selrel.value, cruz_id: bd.value.crz_id,
        b1_id:bd.value.b1_id, b2_id:bd.value.b2_id, nome:bd.value.nome}})      
        .then((resp) => {
          isprocessing.value = false
          q_alert.value = resp.data.q_alert

          if (q_alert.value) {
            msg.value = resp.data.msg
            rel_avan.value = true
          } else {
            $q.notify({
              type: resp.data.cor,
              message: resp.data.msg
            })
          }
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })

    }

    function rel_bt_avan() {
      isprocessing.value = true
      axios.get('/rel_bt_avan', {params:{selrel_avan: selrel_avan.value}})
      .then((resp) => {
        isprocessing.value = false
        q_alert.value = resp.data.q_alert

        if (q_alert.value) {
          msg.value = resp.data.msg
        } else {
          $q.notify({
            type: resp.data.cor,
            message: resp.data.msg
          })
        }
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })
    }

    function onPar(value) {
      par_rev.value = value;
      axios.get('/revisa_row_par', {params: {row: row_rev.value, par: par_rev.value}})
        .then((resp) => {
          if (max_rev.value > row_rev.value){
            row_rev.value += 1
          }
        });
    }

    function onReset () { 
      isprocessing.value = true;
      client_file1.value = null;
      client_file2.value = null;  
      modo_rev.value = false;

      axios.get('/onreset', {params:{cruzamento: cruzamento.value, cruz_id: bd.value.crz_id}})
      .then((resp) => {
        isprocessing.value = false;
        bd.value = resp.data.bd;
        list_rel.value = resp.data.list_rel;
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })    

    }
    
    function onSubmit (evt) {     
      isprocessing.value = true
      textb1.value = "Aguarde"
      textb2.value = "Aguarde"
      let notif = null
      if ((client_file1.value == null) || (client_file2.value == null)) {
        $q.notify({
          color: 'red-5',
          textColor: 'white',
          icon: 'warning',
          message: 'Você precisa escolher os dois bancos'
        });
        bd.importado = 0;
        isprocessing.value = false;
      } else {
        notif = $q.notify({
          type: 'ongoing',     
          message: 'Enviado, aguarde',
          position:'center'
        });
        //console.log( this.client_file1);
        //console.log( this.client_file2);
        //console.log(evt.target);
        
        //var formData = new FormData(evt.target);
        var formData = new FormData();
        //const data = [];

        var cont = 0
        var chave = []
    
        client_file1.value.forEach(file=>{
          cont += 1
          formData.append(`file1_id_${cont}`, file);
          chave.push(`file1_id_${cont}`)
        });        
        
        formData.append("file1_id", chave);
      
        cont = 0
        chave = []
        client_file2.value.forEach(file=>{
          cont += 1
          formData.append(`file2_id_${cont}`, file);
          chave.push(`file2_id_${cont}`)
        });        
        formData.append("file2_id", chave);
          
        formData.append("cruzamento", cruzamento.value);
        
        //console.log(formData)

        axios.post('/sub',
          formData,
          {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
          }
        ).then(function(resp){          
          isprocessing.value = false;
          if (resp.data.cor == 'positive') {
            textb1.value = resp.data.textb1;
            textb2.value = resp.data.textb2;
            update_model_bt.value = true;
            bd.value = resp.data.bd;
          }

          notif({
            type: resp.data.cor,   
            message: resp.data.msg      
          });        
        })
        .catch(function(){  
          notif({
            type: 'negative',
            message: 'Algo deu errado'
          })
          isprocessing.value = false;
        });

        //alert(this.isprocessing)
      
      }
    }

    function onCruzar () {
      isprocessing.value = true
      max_rev.value = 0
      row_rev.value = 0
      let notif = $q.notify({
        type: 'ongoing',
        message: 'Enviado, aguarde',
        position: 'center'
      })

      axios.get('/cruzar')
        .then((resp) => {
          row_rev.value = 1
          max_rev.value = resp.data.max_rev
          modo_rev.value = resp.data.modo_rev
          bd.value.linkado = 1
          textrel.value = resp.data.textrel
          revisado.value = resp.data.revisado
          update_model_bt.value = true
          isprocessing.value = false

          notif({
            type: resp.data.cor,
            message: resp.data.msg
          })
        })
        .catch(() => {
          notif({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
    }

    function conclui_rev_bt () {
      isprocessing.value = true
      modo_rev.value = false     

      axios.get('/conclui_rev_bt', {params: {crz_id: bd.value.crz_id}})
        .then((resp) => {
          isprocessing.value = false
          list_rel.value = resp.data.list_rel
          bd.value.modo_rev = 0
        })
        .catch(() => {
          notif({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })

    }

    onMounted(() => {  
      axios.get('/get_load')
        .then((resp) => {
          console.log(resp)
          cruzamentos.value = resp.data.cruzamentos
          bd.value = resp.data.bd
        });
    });
    
    return {
      leftDrawerOpen,
      onReset,
      onSubmit,
      rel_nsus_covid_pos_Submit,
      rel_bt_pad,
      rel_bt_avan,
      onPar,
      conclui_rev_bt,
      onCruzar,
      isprocessing,
      client_file_ext,
      textext,
      client_file1,
      client_file2, 
      modo_rev,
      cruzamento,
      cruzamentos,
      bd,
      textb1,
      textb2,
      labelb1,
      labelb2,
      cruzado,      
      form_rev,
      cor_rev,
      max_rev,
      row_rev,
      textrel,
      revisado,
      par_rev,
      update_model_bt,
      list_rel,
      selrel,
      list_rel_avan,
      selrel_avan,
      rel_avan,      
      msg,
      q_alert
    }
  }
})

app.use(Quasar, {
  config: {
    // brand: {
    //   primary: '#26a69a'
    // }          
    
  }
})
app.mount('#q-app')
