#' @export

gl.sims <- function(file_var,
                    number_iterations = 1,
                    every_gen = 5,
                    seed = NULL,
                    parallel = FALSE,
                    n.cores = NULL) {

  ##### SIMULATIONS VARIABLES######
  sim_vars <- suppressWarnings(read.csv(file_var))
  sim_vars <- edit(sim_vars)
  vars_assign <- unlist(unname(mapply(paste, sim_vars$var, "<-", sim_vars$val, SIMPLIFY = F)))
  eval(parse(text = vars_assign))
  # setting the seed
  if(!is.null(seed)){
    set.seed(seed)
  }
  
  if (simulation_type_2 == "chillingham"  & simulation_type == "fly") {
    variance_offspring <-  1000000 # variance in family size
    ###### input recombination map
    RecRates_All_Chromosomes <- read_csv("chill_recom_map.csv")
    RecRates_All_Chromosomes <-
      as.data.frame(RecRates_All_Chromosomes)
    RecRates_All_Chromosomes$Chr <-
      as.character(RecRates_All_Chromosomes$Chr)
    RecRates_All_Chromosomes_chr <-
      RecRates_All_Chromosomes[which(RecRates_All_Chromosomes$Chr == chromosome_name), ]
    chr_length <-
      RecRates_All_Chromosomes_chr[nrow(RecRates_All_Chromosomes_chr), "Location"]
    map_cattle_binned <-
      stats.bin(
        RecRates_All_Chromosomes_chr$Location,
        RecRates_All_Chromosomes_chr$`mean sexes`,
        breaks = seq(0, chr_length, map_resolution)
      )
    map_cattle_binned_b <-
      unname(map_cattle_binned$stats[2, ] * map_cattle_binned$stats[1, ])
    map_cattle_binned_b
    map <- as.data.frame(map_cattle_binned_b)
    colnames(map) <- "cM"
    map[is.na(map$cM), ] <- 0
    targets <-  read_csv("chill_targets_of_selection.csv")
    targets$chr_name <- as.character(targets$chr_name)
    targets <- targets[which(targets$chr_name == chromosome_name), ]
    targets <- targets[!duplicated(targets$start), ]
    targets <- targets[!duplicated(targets$end), ]
  }
  if (simulation_type_2 == "fly" & simulation_type == "fly") {
    variance_offspring <-  0.4 # variance in family size
    ###### input recombination map
    map <- read_csv("fly_recom_map.csv")
    map$Chr <- as.character(map$Chr)
    map <- map[which(map$Chr == chromosome_name), ]
    map <- as.data.frame(map$cM / 1000)
    colnames(map) <- "cM"
    map[is.na(map$cM), ] <- 0
    chr_length <- (nrow(map) + 1) * map_resolution
    targets <- read.csv("fly_targets_of_selection_exons.csv")
    targets$chr_name <- as.character(targets$chr_name)
    targets <- targets[which(targets$chr_name == chromosome_name), ]
    targets <- targets[!duplicated(targets$start), ]
    targets <- targets[!duplicated(targets$end), ]
  }
  if (simulation_type_2 == "general") {
    variance_offspring <-  1000000 # variance in family size
  }
  
  ##### REFERENCE VALUES#####
  if (pre_adaptation == F) {
    gen_number_pre_adaptation <- 0
  }
  # if(neutral_simulations == T){selection <- F}
  # This is the total number of generations
  number_generations <-
    gen_number_pre_adaptation + gen_number_dispersal
  ##### REFERENCE TABLES FOR GENERAL SIMULATIONS #####
  if (simulation_type == "general") {
    chromosome_length <- windows_gral * map_resolution
    # The recombination map is generated by creating a table with as many rows as loci_number_to_simulate
    # and one column, which is filled with the recombination rate between loci (c_gral).
    map <- as.data.frame(matrix(nrow = windows_gral))
    map[, 1] <- c_gral / 100
    map[, 2] <- 1
    colnames(map) <- c("cM", "non_synonymous")
    # Adjusting the total number of loci to simulate by adding one more locus to each window because each
    # window (row) contains one msat.  This is done with the aim that the number of adaptive loci and the
    # number of neutral loci are completely independent from each other
    # The neutral locus is located at the middle of the window
    location_neutral_loci_analysis <-
      seq(map_resolution / 2, (nrow(map) * map_resolution), map_resolution)
    # the number of potentially adaptive loci and the number of potentially neutral loci are added to obtain
    # the total number of loci per 100 Kbp window
    loci_number_to_simulate <- loci_number_to_simulate + nrow(map)
    map$NS_density <-
      ceiling(map$non_synonymous / (sum(map$non_synonymous) / loci_number_to_simulate))
    # To determine the location of each locus in the chromosome, first the cM’s and the 100 Kbps are divided
    # between the total number of loci. Then, each locus is placed along the chromosome sequentially using the
    # accumulative sum of cM’s and Kbps for each locus.
    recombination_map <- NULL
    for (value in 1:nrow(map)) {
      temp <- NULL
      temp <-
        as.data.frame(rep((map[value, "cM"] / map[value, "NS_density"]), map[value, "NS_density"]))
      distance <- map_resolution / nrow(temp)
      temp$loc_bp <- distance * (1:nrow(temp))
      if (value == 1) {
        temp$loc_bp <- ceiling(temp$loc_bp)
      } else{
        temp$loc_bp <-
          ceiling(temp$loc_bp + ((value * map_resolution) - map_resolution))
      }
      recombination_map <- rbind(recombination_map, temp)
    }
    # The last element of the first column must be zero, otherwise the recombination function crashes.
    recombination_map[nrow(recombination_map), 1] <- 0
    loci_number <- nrow(recombination_map)
    # In order for the recombination rate to be accurate, we must account for
    # the case when the probability of the total recombination rate is less than
    # 1 (i.e. < 100 cM) or more than 1 (> 100 cM). For the first case, the program
    # subtracts from 1 the sum of all the recombination rates and this value
    # inserted in the last row of the recombination_map table. If this row is
    # chosen as the recombination point, recombination does not occur. For
    # example, if a chromosome of 20 cM’s is simulated, the last row of the
    # recombination_map will have a value of 0.8 and therefore 80% of the times
    # recombination will not occur. For the second case, having more than 100 cM,
    # means that more than 1 recombination event occurs. So, one recombination
    # event is perform for each 100 cM. Then, the program subtracts the number of
    # recombination events from the sum of all the recombination rates and this
    # value inserted in the last row of the recombination_map table, in the same
    # way as in the first case.
    # number of recombination events per meiosis
    recom_event <- ceiling((c_gral * windows_gral) / 100)
    total_cM <- (c_gral * windows_gral)
    # filling the probability of recombination when the total recombination rate
    # is less than an integer (recom_event) and placing it at the end of the 
    # recombination map
    recombination_map[loci_number + 1, 1] <-
      recom_event - sum(recombination_map[, 1])
    recombination_map[loci_number + 1, 2] <-
      recombination_map[loci_number, 2]
    recombination_map$accum <- cumsum(recombination_map[, 1])
    location <-
      lapply(location_neutral_loci_analysis,
             findInterval,
             vec = as.numeric(paste(unlist(
               recombination_map$loc_bp
             ))))
    location[[1]] <- 1
    colnames(recombination_map) <-
      c("c", "locations_deleterious", "accum")
    
    neutral_loci_location <-  as.character(location)
    loci_location <- location
    reference <- as.data.frame(matrix(nrow = loci_number))
    reference$q <- q_gral
    reference$h <- h_gral
    reference$s <- s_gral
    loci_number <- nrow(recombination_map) - 1
    reference$location <- recombination_map[1:loci_number, 2]
    
  }
  
  ##### REFERENCE TABLES FOR FLY SIMULATIONS #####
  if (simulation_type == "fly") {
    recombination_map_temp <- map
    locations_deleterious <- NULL
    if (simulation_type_2 == "fly") {
      targets$targets_temp <- targets$ns - targets$s
      targets$targets <-  targets$targets_temp * targets_factor
      targets <- targets[which(targets$targets > 0), ]
    }
    if (simulation_type_2 == "chillingham") {
      targets$targets <- targets$ns * targets_factor
    }
    transcripts <- as.data.frame(targets)
    for (i in 1:nrow(transcripts)) {
      locations_deleterious_temp <-
        unlist(mapply(
          FUN = function(a, b) {
            seq(from = a,
                to = b,
                by = 4)
          },
          a = unname(unlist(transcripts[i, "start"])),
          b = unname(unlist(transcripts[i, "end"]))
        ))
      locations_deleterious_temp <-
        sample(locations_deleterious_temp, size = transcripts[i, "targets"])
      locations_deleterious <-
        c(locations_deleterious, locations_deleterious_temp)
    }
    # here are added the location of the loci genotyped in the fly experiment
    if (experiment_loci == T) {
      # these are the location of the neutral loci in the simulations
      location_neutral_loci_analysis <-
        c(seq(
          map_resolution / 2,
          (nrow(recombination_map_temp) * map_resolution),
          map_resolution
        ),
        location_msats_experiment)
      location_neutral_loci_analysis <-
        location_neutral_loci_analysis[order(location_neutral_loci_analysis)]
      locations_deleterious <-
        c(locations_deleterious, location_neutral_loci_analysis)
    }
    if (experiment_loci == F) {
      location_neutral_loci_analysis <-
        seq(map_resolution / 2,
            (nrow(recombination_map_temp) * map_resolution),
            map_resolution)
      locations_deleterious <-
        c(locations_deleterious, location_neutral_loci_analysis)
    }
    locations_deleterious <-
      locations_deleterious[order(locations_deleterious)]
    # different transcripts can be located in the same genome location So,
    # repeated deleterious mutations are deleted, however transcripts that are in
    # the same place are taken in account to calculate fitness in the fitness 
    # function
    locations_deleterious <- unique(locations_deleterious)
    
    if (experiment_freq == T) {
      loc_exp_loci <- location_neutral_loci_analysis
      loc_exp_loci <- loc_exp_loci[order(loc_exp_loci)]
      loc_exp_loci <- which(loc_exp_loci %% 10000 != 0)
      loc_exp_loci_2 <-
        unlist(lapply(location_msats_experiment, function(x) {
          which(x == locations_deleterious)
        }))
    }
    
    chromosome_length <-
      (nrow(recombination_map_temp) + 1) * map_resolution
    ############################################################
    ################# DOUBLE CHECK ####################
    ############################################################
    #this is to fix a bug that crashes the program because the last neutral 
    # locus sometimes could be located farther than the last deleterious mutation
    locations_deleterious <-
      c(locations_deleterious, chromosome_length)
    ############################################################
    ############################################################
    ############################################################
    loci_number_to_simulate <- length(locations_deleterious)
    # the recombination map is produced by cross multiplication. the following 
    # lines are the input for doing the cross multiplication.
    recombination_map_temp$midpoint <-
      seq(
        map_resolution / 2,
        nrow(recombination_map_temp) * map_resolution,
        map_resolution
      )
    recombination_temp <-
      unlist(lapply(locations_deleterious, findInterval, vec = as.numeric(paste(
        unlist(recombination_map_temp$midpoint)
      ))))
    # deleterious mutations located below the location in the first row of the 
    # recombination map (i.e. 50000) are assigned to row 0, to correct this they 
    # are reassigned to row number 1
    recombination_temp[recombination_temp == 0] <- 1
    recombination_2 <-
      recombination_map_temp[recombination_temp, "cM"]
    recombination_map <-
      as.data.frame(cbind(locations_deleterious, recombination_2))
    recombination_map$c <- NA
    # the recombination map is produced by cross multiplication
    #not taking in account the last row for the loop to work
    for (deleterious_row in 1:(nrow(recombination_map) - 1)) {
      recombination_map[deleterious_row, "c"] <-
        ((recombination_map[deleterious_row + 1, "locations_deleterious"] - recombination_map[deleterious_row, "locations_deleterious"]) * recombination_map[deleterious_row, "recombination_2"]) / map_resolution
    }
    # The last element of the recombination column must be zero, otherwise the 
    # recombination function crashes.
    recombination_map[nrow(recombination_map), "c"] <- 0
    loci_number <- loci_number_to_simulate
    # In order for the recombination rate to be accurate, we must account for 
    # the case when the probability of the total recombination rate is less than 1 
    # (i.e. < 100 cM). For this end, the program subtracts from 1 the sum of all 
    # the recombination rates and this value inserted in the last row of the 
    # recombination_map table. If this row is chosen as the recombination point, 
    # recombination does not occur. For example, if a chromosome of 20 cM’s is 
    # simulated, the last row of the recombination_map will have a value of 0.8 
    # and therefore 80% of the times recombination will not occur.
    # number of recombination events per meiosis
    recom_event <- ceiling(sum(recombination_map[, "c"]))
    recombination_map[loci_number + 1, "c"] <-
      recom_event - sum(recombination_map[, "c"])
    recombination_map[loci_number + 1, "locations_deleterious"] <-
      recombination_map[loci_number, "locations_deleterious"]
    recombination_map[loci_number + 1, "recombination_2"] <-
      recombination_map[loci_number, "recombination_2"]
    recombination_map$accum <- cumsum(recombination_map[, "c"])
    
    location_temp <- location_neutral_loci_analysis
    location_temp <- location_temp[order(location_temp)]
    location <-
      lapply(location_temp, function(x) {
        which(recombination_map$locations_deleterious == x)
      })
    neutral_loci_location <-  as.character(location)
    loci_location <- location
    
    s <- rlnorm(loci_number,
             meanlog = log(log_mean),
             sdlog = log(log_sd))
    # the equation for dominance (h) was taken from Huber 2018 Nature
    h <- rnorm(loci_number, mean = dominance_mean, sd = sqrt(0.001))
    a <- s * (1 - (2 * h))
    b <- (h * s) * (1 + mutation_rate)
    c <- rep.int(-(mutation_rate), times = loci_number)
    df_q <- as.data.frame(cbind(a, b, c))
    # q is based on the following equation: (s(1-2h)q^2) + (hs(1+u)q) - u = 0, where u is
    # the mutation rate per generation per site. Taken from Crow & Kimura page 260
    q <-
      mapply(
        q_equilibrium,
        a = df_q$a,
        b = df_q$b,
        c = df_q$c,
        USE.NAMES = F
      )
    reference <- as.data.frame(matrix(nrow = loci_number))
    reference$q <- q
    reference$h <- h
    reference$s <- s
    # NS with very small s have a q > 1. Therefore, we set a maximum q value of 
    # 0.5.
    q_more_than_point5 <-
      as.numeric(row.names(reference[reference$q > 0.5,]))
    reference[q_more_than_point5, "q"] <- 0.5
    # the log normal distribution, whith the parameters used in the simulations,
    # generates a few selection coefficients that are > 1. the maximum value of s 
    # is set to 0.99
    s_more_than_one <-
      as.numeric(row.names(reference[reference$s > 1,]))
    reference[s_more_than_one, "s"] <- 0.99
    loci_number <- nrow(reference)
  }
  
  ##### REFERENCE VALUES BOTH SIMULATIONS #####
  # This is to calculate the density of mutations per centimorgan. the density 
  # is based on the number of heterozygous loci in each individual. Based on HW
  # equation (p^2+2pq+q^2), the proportion of heterozygotes (2pq) for each locus 
  # is calculated and then averaged. This proportion is then multiplied by the 
  # number of loci and divided by the length of the chromosome in centiMorgans.
  # According to Haddrill 2010, the mean number of heterozygous deleterious 
  # mutations per fly is 5,000 deleterious amino acid mutations per individual, 
  # with an estimated mean selection coefficient (sh) of 1.1X10^-5. The chromosome
  # arm 2L has 17% of the total number of non-synonymous mutations and is 55/2 cM 
  # long (cM are divided by two because there is no recombination in males), with 
  # these parameters the density per cM is (5000*0.17)/(55/2) = 30.9
  loci_number <- nrow(recombination_map) - 1
  freq_deleterious <-
    reference[-as.numeric(neutral_loci_location),]
  freq_deleterious_b <-
    mean(2 * (freq_deleterious$q) * (1 - freq_deleterious$q))
  density_mutations_per_cm <-
    (freq_deleterious_b * nrow(freq_deleterious)) / (recombination_map[loci_number, "accum"] * 100)
  reference$location <-
    recombination_map[1:loci_number, "locations_deleterious"]

  # one is subtracted from the recombination map to account for the last row that
  # was added in the recombination map to avoid that the recombination function crashes
  plink_map <- as.data.frame(matrix(nrow = loci_number, ncol = 4))
  plink_map[, 1] <- chromosome_name
  plink_map[, 2] <- rownames(recombination_map[-(loci_number + 1), ])
  plink_map[, 3] <- recombination_map[-(loci_number + 1), "accum"]
  plink_map[, 4] <-
    recombination_map[-(loci_number + 1), "locations_deleterious"]
  
  # MIGRATION VARIABLES
  # pick which sex is going to be transferred first
  if (number_transfers >= 2) {
    maletran <- TRUE
    femaletran <- TRUE
  } else if (number_transfers == 1) {
    maletran <- TRUE
    femaletran <- FALSE
  }
  
  dispersal_rate <-
    (number_transfers / transfer_each_gen) / (population_size_dispersal)
  Fst_expected <-
    1 / ((4 * Ne_fst * dispersal_rate) * ((2 / (2 - 1)) ^ 2) + 1)
  shua_expected <-
    (0.22 / (sqrt(2 * Ne_fst * dispersal_rate))) - (0.69 / ((2 * Ne_fst) * sqrt(dispersal_rate)))
  rate_of_loss <- 1 - (1 / (2 * Ne))
  
  ##### START ITERATION LOOP #####
  #this is the list to store the final genlight objects 
  gen_store <- c(seq(1,number_generations, every_gen),number_generations)
  final_res <-
    rep(list(as.list(rep(
      NA, length(gen_store)
    ))), number_iterations)
  
  for (iteration in 1:number_iterations) {
    if (iteration %% 1 == 0) {
      message("iteration = ", iteration)
    }
    
    ##### VARIABLES PRE_ADAPTATION PHASE #######
    if (pre_adaptation == TRUE) {
      population_size <- population_size_pre_adaptation
      dispersal <- dispersal_pre_adaptation
      store_values <- FALSE
    } else{
      population_size <- population_size_dispersal
      dispersal <- dispersal_dispersal
      store_values <- TRUE
    }
    
    ##### INITIALISE POPS #####
    pops_vector <- 1:number_pops
    pop_list <- lapply(pops_vector,function(x){
      initialise(
        pop_number = x,
        pop_size = population_size,
        refer = reference,
        n_l_loc = neutral_loci_location,
        exp_freq = experiment_freq,
        sim_type = simulation_type
      )
    })
   
    ##### START GENERATION LOOP ######
    for (generation in 1:number_generations) {
      if (generation %% 5 == 0) {
        message("generation = ", generation)
      }
      ##### VARIABLES DISPERSAL PHASE ######
      if (dispersal == TRUE) {
        dispersal_pairs <- as.data.frame(expand.grid(pops_vector,pops_vector))
        dispersal_pairs$same_pop <- dispersal_pairs$Var1 == dispersal_pairs$Var2
        dispersal_pairs <- dispersal_pairs[which(dispersal_pairs$same_pop==FALSE),]
        colnames(dispersal_pairs) <- c("pop1","pop2","same_pop")
        
        for(dis_pair in 1:nrow(dispersal_pairs)){
          res <- migration(
            population1 = pop_list[[dispersal_pairs[dis_pair,"pop1"]]],
            population2 = pop_list[[dispersal_pairs[dis_pair,"pop2"]]],
            generation = generation,
            pop_size = population_size,
            trans_gen = transfer_each_gen,
            male_tran = maletran,
            female_tran = femaletran,
            n_transfer = number_transfers
          )
          
          pop_list[[dispersal_pairs[dis_pair,"pop1"]]] <- res[[1]]
          pop_list[[dispersal_pairs[dis_pair,"pop1"]]]$V2 <- dispersal_pairs[dis_pair,"pop1"]
          pop_list[[dispersal_pairs[dis_pair,"pop2"]]] <- res[[2]]
          pop_list[[dispersal_pairs[dis_pair,"pop2"]]]$V2 <- dispersal_pairs[dis_pair,"pop2"]
          maletran <- res[[3]]
          femaletran <- res[[4]]
        }
  
      }
      if (generation == (gen_number_pre_adaptation + 1)) {
        population_size <- population_size_dispersal
        dispersal <- dispersal_dispersal
        store_values <- TRUE
        # counter to store genlight objects
        count_store <- 0
        # counter to store values every generation
        gen_dispersal <- 0
          
        if (pre_adaptation == TRUE) {
          if (same_line == TRUE) {
            # pop1_temp is used because pop1 is used to sample pop2
            pop1_temp <-
              rbind(pop1[sample(which(pop1$V1 == "Male"), size = population_size / 2),],
                    pop1[sample(which(pop1$V1 == "Female"), size = population_size / 2),])
            pop1$V2 <- 1
            pop2 <-
              rbind(pop1[sample(which(pop1$V1 == "Male"), size = population_size / 2),],
                    pop1[sample(which(pop1$V1 == "Female"), size = population_size / 2),])
            pop2$V2 <- 2
            pop1 <- pop1_temp
          }
          if (same_line == FALSE) {
            pop1 <-
              rbind(pop1[sample(which(pop1$V1 == "Male"), size = population_size / 2),],
                    pop1[sample(which(pop1$V1 == "Female"), size = population_size /
                                  2),])
            pop1$V2 <- 1
            pop2 <-
              rbind(pop2[sample(which(pop2$V1 == "Male"), size = population_size / 2),],
                    pop2[sample(which(pop2$V1 == "Female"), size = population_size /  2),])
            pop2$V2 <- 2
          }
        }
      }
      # generation counter
      if (store_values == TRUE) {
        gen_dispersal <- gen_dispersal + 1
      }
      ##### REPRODUCTION#########
      if (simulation_type_2 == "fly") {
        offspring_pop1 <-
          reproduction(
            pop = pop1,
            pop_number = 1,
            pop_size = population_size,
            var_off = variance_offspring,
            num_off = number_offspring,
            r_event = recom_event,
            recom = recombination,
            r_males = recombination_males,
            r_map_1 = recombination_map,
            n_loc = loci_number
          )
        offspring_pop2 <-
          reproduction(
            pop = pop2,
            pop_number = 2,
            pop_size = population_size,
            var_off = variance_offspring,
            num_off = number_offspring,
            r_event = recom_event,
            recom = recombination,
            r_males = recombination_males,
            r_map_1 = recombination_map,
            n_loc = loci_number
          )
      }
      if (simulation_type_2 == "chillingham") {
        offspring_pop1 <-
          reproduction_2(
            pop = pop1,
            pop_number = 1,
            pop_size = population_size,
            var_off = variance_offspring,
            num_off = number_offspring,
            r_event = recom_event,
            recom = recombination,
            r_males = recombination_males,
            r_map_1 = recombination_map,
            n_loc = loci_number
          )
        offspring_pop2 <-
          reproduction_2(
            pop = pop2,
            pop_number = 2,
            pop_size = population_size,
            var_off = variance_offspring,
            num_off = number_offspring,
            r_event = recom_event,
            recom = recombination,
            r_males = recombination_males,
            r_map_1 = recombination_map,
            n_loc = loci_number
          )
      }
      if (simulation_type_2 == "general") {
        offspring_list <- lapply(pops_vector,function(x){
          reproduction_2(
            pop = pop_list[[x]],
            pop_number = x,
            pop_size = population_size,
            var_off = variance_offspring,
            num_off = number_offspring,
            r_event = recom_event,
            recom = recombination,
            r_males = recombination_males,
            r_map_1 = recombination_map,
            n_loc = loci_number
          )
        })
      }
      
      ##### SELECTION ####
      if (selection == TRUE) {
        offspring_list <- lapply(pops_vector,function(x){
          selection_fun(offspring = offspring_list[[x]], 
                        reference_pop = reference,
                        sel_model = natural_selection_model)
        })
      }
      ##### SAMPLING NEXT GENERATION #########
      
      test_extinction <- unlist(lapply(pops_vector,function(x){
        length(which(offspring_list[[x]]$V1 == "Male")) < population_size / 2 |
          length(which(offspring_list[[x]]$V1 == "Female")) < population_size / 2
      }))
      
      if (any(test_extinction==TRUE)) {
        pops_extinct <- which(test_extinction==TRUE)
        cat(important("Population",pops_extinct,"became EXTINCT at generation",generation,"\n"))
        cat(important("Breaking this iteration and passing to the next iteration","\n"))
        break()
      }
     
      if (selection == FALSE) {
        pop_list <- lapply(pops_vector,function(x){
          rbind(offspring_list[[x]][sample(which(offspring_list[[x]]$V1 == "Male"), 
                                         size =  population_size / 2),],
                offspring_list[[x]][sample(which(offspring_list[[x]]$V1 == "Female"), 
                                      size = population_size / 2),])
        })
      }
      
      if (selection == TRUE & natural_selection_model == "absolute") {
        pop_list <- lapply(pops_vector,function(x){
          rbind(offspring_list[[x]][sample(which(offspring_list[[x]]$V1 == "Male"), 
                                           size =  population_size / 2),],
                offspring_list[[x]][sample(which(offspring_list[[x]]$V1 == "Female"), 
                                           size = population_size / 2),])
        })
      }
      
      if (selection == TRUE & natural_selection_model == "relative") {
        # We modeled selection as Lesecque et al. 2012: offspring are randomly
        # selected to become parents of the next generation in proportion to
        # their relative fitness, for example, if we had four individuals
        # with fitness (W) of 0.1, 0.2, 0.3, and 0.2 the first individual
        # would be selected on average 0.1/(0.1+0.2+0.3+0.2)=0.125 of the time
        # to become parent of the next generation. The vector of probabilities
        # used in sample is multiplied by two because in the selection function
        # (selection_fun), the proportional relative fitness was calculated for
        # all offspring together, and below the males and females are separated
        # in groups, with the objective that exactly the parents of the next
        # generation are half males and half females
        
        pop_list <- lapply(pops_vector,function(x){
          males_pop <- offspring_list[[x]][which(offspring_list[[x]]$V1 == "Male"),]
          females_pop <- offspring_list[[x]][which(offspring_list[[x]]$V1 == "Female"),]
          
          rbind(males_pop[sample(row.names(males_pop),size = (population_size / 2),prob = (males_pop$relative_fitness * 2)), ],
                females_pop[sample(row.names(females_pop),size = (population_size / 2),prob = (females_pop$relative_fitness * 2)), ])
        })
      }
      ###### STORE VALUES ########
      if (generation %in% gen_store) {
        # counter to store genlight objects
        count_store <- count_store+1
        pop_names <- rep(paste0("pop",pops_vector),population_size)
        pop_names <- pop_names[order(pop_names)]
        df_genotypes <- rbindlist(pop_list)
        df_genotypes$V1[df_genotypes$V1 == "Male"]   <- 1
        df_genotypes$V1[df_genotypes$V1 == "Female"] <- 2
        df_genotypes[, 2] <- pop_names
        df_genotypes$id <- paste0(unlist(unname(df_genotypes[, 2])), "_", rep(1:population_size,length(pops_vector)))
        plink_ped <- apply(df_genotypes, 1, ped, n_loc = loci_number)
        # converting allele names to numbers
        plink_ped <- gsub("a", "1", plink_ped) 
        plink_ped <- gsub("A", "2", plink_ped)
        plink_ped <-
          lapply(plink_ped, function(x) {
            gsub(" ", "", strsplit(x, '(?<=([^ ]\\s){2})', perl = TRUE)[[1]])
          })
        plink_ped_2 <- lapply(plink_ped, function(x) {
          x[x == "22"] <- 2
          x[x == "11"] <- 0
          x[x == "21"] <- 1
          x[x == "12"] <- 1
          return(x)
        })
        
        if (parallel && is.null(n.cores)) {
          n.cores <- parallel::detectCores()
        }
        
        loc.names <- 1:nrow(reference)
        n.loc <- length(loc.names)
        misc.info <- lapply(1:6, function(i)
          NULL)
        names(misc.info) <-
          c("FID", "IID", "PAT", "MAT", "SEX", "PHENOTYPE")
        res <- list()
        temp <-
          as.data.frame(cbind(
            df_genotypes[,2],
            df_genotypes[,7],
            df_genotypes[,5],
            df_genotypes[,6],
            df_genotypes[,1],
            1
          ))
        
        for (i in 1:6) {
          misc.info[[i]] <- temp[, i]
        }
        txt <-
          lapply(plink_ped_2, function(e)
            suppressWarnings(as.integer(e)))
        if (parallel) {
          res <-
            c(
              res,
              parallel::mclapply(txt, function(e)
                new("SNPbin", snp = e, ploidy = 2L), mc.cores = n.cores, mc.silent = TRUE, mc.cleanup = TRUE, mc.preschedule = FALSE)
            )
        } else {
          res <-
            c(res, lapply(txt, function(e)
              new(
                "SNPbin", snp = e, ploidy = 2L
              )))
        }
        
        res <-
          new("genlight",
              res,
              ploidy = 2L,
              parallel = parallel)
        indNames(res) <- misc.info$IID
        pop(res) <- misc.info$FID
        locNames(res) <- loc.names
        misc.info <- misc.info[c("SEX", "PHENOTYPE", "PAT", "MAT")]
        names(misc.info) <- tolower(names(misc.info))
        misc.info$sex[misc.info$sex == 1] <- "m"
        misc.info$sex[misc.info$sex == 2] <- "f"
        misc.info$sex <- factor(misc.info$sex)
        misc.info$phenotype[misc.info$phenotype == 1] <- "control"
        misc.info$phenotype[misc.info$phenotype == 2] <- "case"
        misc.info$phenotype <- factor(misc.info$phenotype)
        res$other$ind.metrics <- as.data.frame(misc.info)
        loc_metrics_temp <-
          as.data.frame(cbind(plink_map, reference[, 2:4]))
        colnames(loc_metrics_temp) <-
          c("chr", "loc_id", "loc_cM", "loc_bp", "q", "h", "s")
        res$other$loc.metrics <- loc_metrics_temp
        sim_vars_temp <- setNames(data.frame(t(sim_vars[,-1])), sim_vars[,1])
        sim_vars_temp$generation <- generation
        sim_vars_temp$iteration <- iteration
        sim_vars_temp$seed <- seed
        res$other$sim.vars <- sim_vars_temp
        
        final_res[[iteration]][[count_store]] <- res
      }
    }
  }
  #removing NA's from results
  final_res <- lapply(final_res, function(x) x[!is.na(x)])
  return(final_res)
}