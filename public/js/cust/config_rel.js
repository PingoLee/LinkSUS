const { createApp, ref, onMounted, watch, methods } = Vue;
const { useQuasar } = Quasar


const app = Vue.createApp({
  name: 'MyLayout',
  setup () {
    const leftDrawerOpen = ref(true)
    const isprocessing = ref(false)
    const $q = useQuasar()

    // comoun
    const col_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "col", label: "Variável", field: "col", align: "left" },
      { name: "inrel", label: "Inserir", field: "inrel", align: "center" }
    ]);
    const col_edit_row = ref({})
    const vis_cols = ref(["ordem", "col", "obrig", "inrel"])

    // table bd1
    const col_b1_imp = ref([])
    const col_b1_filter = ref("")

    // table bd1
    const col_b2_imp = ref([])
    const col_b2_filter = ref("")

    // select rel (manage info about report selects)
    const list_crz = ref([])
    const selcrz = ref("")
    const list_rel = ref([])
    const obs_rel = ref("")
    const dict_crz = ref({})
    const selrel = ref("")
    const info_rel = ref({})
    const show_rel = ref(false)

    // table rel
    const col_cz_imp = ref([])
    const col_cz_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "var_org_id", label: "var_org_id", align: "left", field: "var_org_id" },
      { name: "var_org", label: "Origem", align: "left", field: "var_org" },
      { name: "var_rel", label: "Relatório", align: "left", field: "var_rel" },
      { name: "bd", label: "Banco", align: "left", field: "bd" },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);
    const col_cz_filter = ref("")
    const vis_cols_cz = ref(["ordem", "var_org", "var_rel", "bd", "actions"])
    const show_cz = ref(false)
    const rel_edit_row = ref({})
    const cz_row = ref({});


    // tables pos-processing
    const data_pos = ref([]);
    const col_pos_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "function", label: "Função", align: "left", field: "function" },
      { name: "definition", label: "Definição", field: "definition", align: "left" },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);
    const vis_cols_pos = ref(["ordem", "function", "definition", "actions"])
    const show_pos = ref(false)
    const pos_edit_row = ref({})
  
    // tables advanced reports
    // data_avan::R{Vector} = []; col_avan_def::R{Vector} = col_avan_def; vis_cols_avan::R{Vector} = ["ordem", "nome", "function", "definition", "actions"]
    // show_avan::R{Bool} = false; avan_edit_row::R{Dict} = Dict(); avan_edit_bt::R{Bool} = false; avan_del_bt::R{Bool} = false
    const data_avan = ref([]);    
    const col_avan_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "nome", label: "Nome", align: "left", field: "nome" },
      { name: "function", label: "Função", align: "left", field: "function" },
      { name: "definition", label: "Definição", field: "definition", align: "left" },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);
    const vis_cols_avan = ref(["ordem", "nome", "function", "definition", "actions"])
    const show_avan = ref(false)
    const avan_edit_row = ref({})


    watch(selcrz, (val, oldVal) => {
      if (val != "") {
        isprocessing.value = true
        axios.get("/config_rel_back", {params: {resposta: 'selcrz', selcrz: val}})
        .then(response => {
          isprocessing.value = false
          list_rel.value = response.data.list_rel;
          dict_crz.value = response.data.dict_crz;
          selrel.value = response.data.selrel;
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
      }
    })

    watch(selrel, (val, oldVal) => {
      isprocessing.value = true
      axios.get("/config_rel_back", {params: {resposta: 'selrel', selrel: val, selcrz: selcrz.value}})
      .then(response => {
        isprocessing.value = false
        col_b1_imp.value = response.data.col_b1_imp;
        col_b2_imp.value = response.data.col_b2_imp;
        col_cz_imp.value = response.data.col_cz_imp;
        obs_rel.value = response.data.obs_rel;
        data_pos.value = response.data.data_pos;
        data_avan.value = response.data.data_avan;
        
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })
    })  

    const methods = {
      edit_row_rel(props) {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um relatório primeiro',
            position:'top'
          });
        } else {
          cz_row.value = Object.assign({}, props.row);
          show_cz.value = true
        }
      },      
      up_row_rel(props) {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um relatório primeiro',
            position:'top'
          });
        } else {
          cz_row.value = Object.assign({}, props.row);
          axios.get("/config_rel_back", {params: {resposta: 'up_row_bt', ordem:cz_row.value.ordem, id_row:cz_row.value.id, selrel: selrel.value}})
          .then(response => {
            isprocessing.value = false
            col_cz_imp.value = response.data.col_cz_imp;
          })
          .catch(() => {
            $q.notify({
              type: 'negative',
              message: 'Algo deu errado'
            })
          })
        }
      }, 
      down_row_rel(props) {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um relatório primeiro',
            position:'top'
          });
        } else {
          cz_row.value = Object.assign({}, props.row);
          axios.get("/config_rel_back", {params: {resposta: 'down_row_bt', ordem:cz_row.value.ordem,  id_row:cz_row.value.id, selrel: selrel.value}})
          .then(response => {
            isprocessing.value = false
            col_cz_imp.value = response.data.col_cz_imp;
          })
          .catch(() => {
            $q.notify({
              type: 'negative',
              message: 'Algo deu errado'
            })
          })
        }
      }, 
      del_row_rel(props) {
        isprocessing.value = true
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um relatório primeiro',
            position:'top'
          });
        } else {
          cz_row.value = Object.assign({}, props.row);
          axios.get("/config_rel_back", {params: {resposta: 'del_cz_bt', id_row:cz_row.value.id, selrel: selrel.value, selcrz: selcrz.value}})
          .then(response => {
            isprocessing.value = false
            col_cz_imp.value = response.data.col_cz_imp;
            col_b1_imp.value = response.data.col_b1_imp;
            col_b2_imp.value = response.data.col_b2_imp;
          })
          .catch(() => {
            $q.notify({
              type: 'negative',
              message: 'Algo deu errado'
            })
          })
        }
      },
      insert_new_row_rel(props) {
        if (props.row.inrel == false){
          notif = $q.notify({
            color: 'warning',
            icon: 'warning',
            message: 'Para excluir a variável, clique no botão excluir na tabela a baixo',
            position:'center'
          });
          props.row.inrel = true
        } else {
          col_edit_row.value = Object.assign({}, props.row);
          isprocessing.value = true
          axios.get("/config_rel_back", {params: {resposta: 'col_bt', id_row:col_edit_row.value.id, banco_id:col_edit_row.value.banco_id, selrel: selrel.value}})
          .then(response => {
            isprocessing.value = false
            col_cz_imp.value = response.data.col_cz_imp;
          })
        }
      },
      insert_new_rel() {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um cruzamento primeiro',
            position:'top'
          });
        } else {
          info_rel.value = {'id':0, 'nome':'', 'obs':''}
          show_rel.value = true;
        }
      },
      edit_def_rel(row) {
        // filter the row from list_rel and return object to info_rel
        let row_obj = list_rel.value.filter((obj) => {obj.id == row})

        info_rel.value = Object.assign({}, props.row);
        show_rel.value = true;
      },      
      add_pos_col() {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um cruzamento primeiro',
            position:'top'
          });
        } else {
          pos_edit_row.value = {"id": 0, "function":"", "definition":""};
          show_pos.value = true;
        }
      },
      edit_pos_col(props) {
        pos_edit_row.value = Object.assign({}, props.row);
        show_pos.value = true;
      },
      del_pos_col() {
        pos_edit_row.value = Object.assign({}, props.row);
        pos_del_bt.value = true;
      },
      add_avan_col() {
        if (selcrz.value == "") {
          notif = $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um cruzamento primeiro',
            position:'top'
          });
        } else {
          avan_edit_row.value = {"id": 0, "function":"", "definition":""};
          show_avan.value = true;
        }
      },
      edit_avan_col(props) {
        avan_edit_row.value = Object.assign({}, props.row);
        show_avan.value = true;
      },
      del_avan_col(props) {
        avan_edit_row.value = Object.assign({}, props.row);
        avan_del_bt.value = true;
      },
      save_row_bt() {
        isprocessing.value = true
        axios.get("/config_rel_back", {params: {resposta: 'save_row_bt', id_row:cz_row.value.id, var_rel:cz_row.value.var_rel, selrel: selrel.value}})
        .then(response => {
          isprocessing.value = false;
          col_cz_imp.value = response.data.col_cz_imp;
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
      }
    }

    onMounted(() => {
      isprocessing.value = true
      axios.get("/config_rel_back", {params: {resposta: 'get_crz'}})
      .then(response => {
        isprocessing.value = false
        list_crz.value = response.data.get_crz;      
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })

    });

    return {
      leftDrawerOpen,
      isprocessing,
      ...methods,
      // tables definitions
      col_def,
      col_cz_def,
      col_pos_def,
      col_avan_def,
      // variables
      selcrz,
      cz_row,
      show_cz,
      col_edit_row,
      info_rel,
      show_rel,
      pos_edit_row,
      show_pos,
      avan_edit_row,
      show_avan,
      vis_cols,
      vis_cols_cz,
      // return other constants
      list_crz,
      selrel,
      list_rel,
      obs_rel,
      dict_crz,
      col_b1_imp,
      col_b1_filter,
      col_b2_imp,
      col_b2_filter,
      col_cz_imp,
      col_cz_filter,
      data_pos,
      vis_cols_pos,
      data_avan,
      vis_cols_avan


      
    }
  }
});

app.use(Quasar, {
  config: {
    // brand: {
    //   primary: '#26a69a'
    // }

  }
})
app.mount('#q-app')
