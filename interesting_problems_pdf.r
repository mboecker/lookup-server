devtools::load_all("omlTuneBenchRLocal/")

# Create a big RDS file
#big_list = lapply(get_available_tasks(), function(task_id) {
big_list = lapply(c(3,282), function(task_id) {
  rbindlist(lapply(get_available_algos(), function(algo_id) {
    if(nrow(get_runs(algo_id, task_id)) == 0) {
      data.frame()
    } else {
      cbind(task_id, get_runs(algo_id, task_id))
    }
  }), fill = TRUE)
})
big_list = rbindlist(big_list, fill = TRUE)
ordering = names(big_list)
ordering[c(4,5,9,10)] = ordering[c(9,10,4,5)]
setcolorder(big_list, ordering)
saveRDS(big_list, file = "big.rds")

# Now, create a beautiful document with all the data and plots
create_page_for_task = function(task) {
  
}

pages = sapply(get_available_tasks(), create_page_for_task)
