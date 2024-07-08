const { createApp, ref, onMounted, watch, methods } = Vue;
const { useQuasar } = Quasar


const app = Vue.createApp({
  name: 'MyLayout',
  setup () {
    const leftDrawerOpen = ref(true)
    const isprocessing = ref(false)
    const $q = useQuasar()

    // tables mnipulations
    const col_imp = ref([]);
    const col_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "col", label: "Variável", field: "col", align: "left" },
      { name: "function", label: "Função", field: "function", align: "left" },
      { name: "obrig", label: "Obrig", field: "obrig", align: "center" },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);    
    const col_filter = ref("");
    const vis_cols = ref(["ordem", "col", "function", "obrig", "actions"]);
    const col_obr = ref({
      1: "Número que o sistema dá para o registro (ex.: número da notificação)",
      2: "Nome do cidadão",
      3: "Nome da mãe do cidadão",
      4: "Data de nascimento",
      5: "Data do registro no sistema (ex.: data da notificação)",
      6: "Sexo",
      7: "Código do IBGE (6 dígitos) do município de residência",
      8: "Endereço de residência"
    });
    const show_dialog = ref(false);
    const edit_row = ref({});
    const show_mul_col = ref(false);
    const mult_data = ref("");

    // tables replacing
    const col_replc = ref([]);
    const col_replc_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "antigo", label: "Tx. orig.", align: "left", field: "antigo", sortable: true },
      { name: "novo", label: "Tx. novo", field: "novo", align: "left", sortable: true },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);
    const col_replc_filter = ref("");
    const vis_cols_replc = ref(["antigo", "novo", "actions"]);
    const show_replc = ref(false);
    const replc_edit_row = ref({});
    const replc_del_bt = ref(false);

    // tables pre-processing
    const col_prep = ref([]);
    const col_prep_def = ref([
      { name: "id", label: "id", align: "left", field: "id" },
      { name: "ordem", label: "Ordem", align: "left", field: "ordem" },
      { name: "function", label: "Função", align: "left", field: "function" },
      { name: "definition", label: "Definição", field: "definition", align: "left" },
      { name: "actions", label: "Ação", field: "", align: "center" }
    ]);
    const vis_cols_prep = ref(["ordem", "function", "definition", "actions"]);
    const show_prep = ref(false);
    const prep_edit_row = ref({});
    const prep_del_bt = ref(false);

    // bancos
    const bds_list = ref([]); // Placeholder for get_bds() equivalent in Vue
    const bdsel = ref(null);
    const bdobs = ref("");

    const methods = {
      edit_bt() {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'edit_bt', function: edit_row.value.function, id_row: edit_row.value.id,
          col: edit_row.value.col, obrig: edit_row.value.obrig, ordem: edit_row.value.ordem, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_imp.value = response.data.col_imp;
        })
      },
      prep_edit_bt() {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'prep_edit_bt', function: prep_edit_row.value.function, id_row: prep_edit_row.value.id,
          definition: prep_edit_row.value.definition, ordem: prep_edit_row.value.ordem, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_prep.value = response.data.col_prep;
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
      },
      bdobs_bt() {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'bdobs_bt', bdobs: bdobs.value, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
      },
      editRow(props) {
        edit_row.value = Object.assign({}, props.row);
        show_dialog.value = true;
      },
      add_col() {
        if (bdsel.value == null) {
          const qsr = useQuasar();
          qsr.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um banco primeiro',
            position: 'center'
          });
        } else {
          edit_row.value = { "id": 0, "ordem": col_imp.value.length + 1, "col": "", "function": "", 'obrig': true };
          show_dialog.value = true;
        }
      },
      del_col(props) {
        edit_row.value = Object.assign({}, props.row);
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'del_bt', id_row: edit_row.value.id, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_imp.value = response.data.col_imp;
        })
      },
      add_mult_var() {
        if (bdsel.value == null) {
          $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um banco primeiro',
            position: 'center'
          });
        } else if (col_imp.value.length < 8) {
          $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Você precisa informar as 8 primeiras variáveis antes de usar essa opção',
            position: 'center'
          });
        } else {
          show_mul_col.value = true;
        }
      },
      edit_mult_var() {
        if (bdsel.value == null) {
          $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um banco primeiro',
            position: 'center'
          });
        } else if (!mult_data.value) {
          $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Você precisa informar as variáveis antes de salvar',
            position: 'center'
          });
        } else {
          isprocessing.value = true
          axios.get("/config_back", {params: {resposta: 'mult_bt', mult_data: mult_data.value, bdsel: bdsel.value}})
          .then(response => {
            isprocessing.value = false
            col_imp.value = response.data.col_imp;
            mult_data.value = "";
          })
        }
      },
      add_replc_col() {
        if (bdsel.value == null) {
          $q.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um banco primeiro',
            position: 'center'
          });
        } else {
          replc_edit_row.value = { "id": 0, "antigo": "", "novo": "" };
          show_replc.value = true;
        }
      },
      edit_replc_col(props) {
        replc_edit_row.value = Object.assign({}, props.row);
        show_replc.value = true;
      },
      del_replc_col(props) {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'replc_del_bt', id_row: props.row.id, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_replc.value = response.data.col_replc;
        })
      },
      add_prep_col() {
        if (bdsel.value == null) {
          const qsr = useQuasar();
          qsr.notify({
            color: 'red',
            icon: 'announcement',
            message: 'Escolha um banco primeiro',
            position: 'center'
          });
        } else {
          prep_edit_row.value = { "id": 0, "function": "", "definition": "" };
          show_prep.value = true;
        }
      },
      edit_prep_col(props) {
        prep_edit_row.value = Object.assign({}, props.row);
        show_prep.value = true;
      },
      del_prep_col(props) {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'prep_del_bt', id_row: props.row.id, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_prep.value = response.data.col_prep;
          prep_del_bt.value = false;
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
      },
      replc_edit_bt() {
        isprocessing.value = true
        axios.get("/config_back", {params: {resposta: 'replc_edit_bt', antigo: replc_edit_row.value.antigo, novo: replc_edit_row.value.novo, id_row: replc_edit_row.value.id, bdsel: bdsel.value}})
        .then(response => {
          isprocessing.value = false
          col_replc.value = response.data.col_replc;
        })
      },      
    };

    function obrigRow(props) {
      console.log(props.row)
      edit_row.value = Object.assign({}, props.row);
      axios.get("/config_back", {params: {resposta: 'obrig_bt', id_row: edit_row.value.id, obrig:edit_row.value.obrig, bdsel: bdsel.value}})
      .then(response => {
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })
    }

    watch(bdsel, (newVal, oldVal) => {
      isprocessing.value = true
      axios.get("/config_back", {params: {resposta: 'watch_bdsel', bdsel: newVal}})
      .then(response => {
        console.log(response)
        isprocessing.value = false
        col_imp.value = response.data.col_imp;
        col_replc.value = response.data.col_replc;
        col_prep.value = response.data.col_prep;
        bdobs.value = response.data.bdobs;
      })
      .catch(() => {
        $q.notify({
          type: 'negative',
          message: 'Algo deu errado'
        })
      })
    });


    onMounted(() => {
      axios.get('/config_back', {params: {resposta: 'get_bds'}} )
        .then(response => {
          bds_list.value = response.data;
        })
        .catch(() => {
          $q.notify({
            type: 'negative',
            message: 'Algo deu errado'
          })
        })
    });

    return {
      ...methods,
      isprocessing,
      leftDrawerOpen,
      col_imp,
      col_def,
      col_filter,
      vis_cols,
      col_obr,
      show_dialog,
      edit_row,
      show_mul_col,
      mult_data,
      col_replc,
      col_replc_def,
      col_replc_filter,
      vis_cols_replc,
      show_replc,
      replc_edit_row,
      replc_del_bt,
      col_prep,
      col_prep_def,
      vis_cols_prep,
      show_prep,
      prep_edit_row,
      prep_del_bt,
      bds_list,
      bdsel,
      bdobs,
      obrigRow
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
