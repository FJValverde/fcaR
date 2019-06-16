.process_batch <- function(LHS, RHS, rules, verbose = TRUE) {

  # Initialize results
  new_LHS <- Matrix(0,
                    nrow = nrow(LHS),
                    ncol = 1,
                    sparse = TRUE)

  new_RHS <- Matrix(0,
                    nrow = nrow(LHS),
                    ncol = 1,
                    sparse = TRUE)

  my_functions <- c("generalization" = .remove_redundancies_lhs_rhs_general,
                    "composition"    = .compose_lhs_rhs_equal,
                    "reduction"      = .reduce_lhs_rhs,
                    "simplification" = .simplify_lhs_rhs,
                    "simpl_ijar"     = .simplify_IJAR_lhs_rhs)

  idx_rules <- match(rules, names(my_functions))
  idx_rules <- idx_rules[!is.na(idx_rules)]
  rules_to_apply <- my_functions[idx_rules]
  rule_names <- names(my_functions)[idx_rules]

  # Begin the timing
  tic("batch")

  if (verbose) {

    cat("Processing batch\n")#, i, "out of", length(idx) - 1, "\n")

  }

  old_LHS <- LHS
  old_RHS <- RHS
  new_cols <- ncol(LHS)

  # Loop over all functions
  for (j in seq_along(idx_rules)) {

    current_cols <- new_cols

    current_rule <- rules_to_apply[[j]]

    tic("rule")
    L <- current_rule(old_LHS, old_RHS)

    rule_time <- toc(quiet = TRUE)
    old_LHS <- L$lhs
    old_RHS <- L$rhs

    new_cols <- ncol(old_LHS)

    if (verbose) {

      cat("-->", rule_names[j], ": from", current_cols, "to",
          new_cols, "in", rule_time$toc - rule_time$tic, "secs. \n")

    }

  }

  # Add the computed implications to the set
  new_LHS <- cbind(new_LHS, old_LHS)
  new_RHS <- cbind(new_RHS, old_RHS)

  batch_toc <- toc(quiet = TRUE)

  if (verbose) {

    cat("Batch took", batch_toc$toc - batch_toc$tic, "secs. \n")

  }

  return(list(lhs = new_LHS[, -1], rhs = new_RHS[, -1]))

}