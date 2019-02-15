devtools::load_all("omlTuneBenchRLocal/")

get_runs_local = function(algo_id, task_id) {
  fname = paste0("docker/omlbotlookup/app/rdsdata/data_", algo_id, "_", task_id, ".rds")
  if(file.exists(fname))
  {
    readRDS(fname)
  }
  else 
  {
    data.frame()
  }
}

# Create a big RDS file
big_list = lapply(get_available_tasks(), function(task_id) {
#big_list = lapply(c(3,282), function(task_id) {
  rbindlist(lapply(get_available_algos(), function(algo_id) {
    if(nrow(get_runs_local(algo_id, task_id)) == 0) {
      data.frame()
    } else {
      cbind(task_id, algo_id, get_runs_local(algo_id, task_id))
    }
  }), fill = TRUE)
})
big_list = rbindlist(big_list, fill = TRUE)
ordering = names(big_list)
ordering[c(4,5,9,10) + 1] = ordering[c(9,10,4,5) + 1]
setcolorder(big_list, ordering)
saveRDS(big_list, file = "big.rds")
