# The tests this paper reports.
#
# Unlike a small-sample re-analysis, nothing here is short of pairs: the subset
# comparison has a hundred of them. The work is therefore about size rather than
# about detectability, so every test is reported next to the magnitude it is
# testing and next to the variation the method shows against itself.

# Sign test on the paired differences, two-sided and exact. Ties are counted and
# dropped, which is the convention, but the count is returned so the manuscript
# can print it instead of quietly losing observations.
sign_test <- function(differences) {
  ties <- sum(differences == 0)
  kept <- differences[differences != 0]
  positive <- sum(kept > 0)
  list(n = length(differences), n_tested = length(kept), ties = ties,
       positive = positive, negative = length(kept) - positive,
       p = stats::binom.test(positive, length(kept))$p.value)
}

wilcoxon_paired <- function(a, b) {
  suppressWarnings(stats::wilcox.test(a, b, paired = TRUE))$p.value
}

paired_t <- function(a, b) {
  fit <- stats::t.test(a, b, paired = TRUE)
  list(estimate = unname(fit$estimate), p = fit$p.value,
       lower = fit$conf.int[1], upper = fit$conf.int[2])
}

# A percentile bootstrap over the paired differences. The records carry their own
# bootstrap intervals; this one is recomputed here so the manuscript quotes an
# interval whose construction it can state, and so the two can be printed side by
# side rather than one standing in for the other.
bootstrap_mean <- function(x, samples = 1000L, seed = 20260822L) {
  set.seed(seed)
  draws <- vapply(seq_len(samples),
                  function(i) mean(sample(x, length(x), replace = TRUE)),
                  numeric(1))
  quantile(draws, c(0.025, 0.975), names = FALSE)
}

# The mean printed in a summary record must be the mean of the per-crop rows that
# record claims to summarise. If it is not, the summary is describing a different
# pixel set and the manuscript would be joining two populations.
assert_recorded_mean <- function(values, recorded, label, tol = 1e-9) {
  if (abs(mean(values) - recorded) > tol) {
    stop(label, ": the recorded mean does not come from the per-crop rows")
  }
  invisible(mean(values))
}

# How the gap compares with the only variation the record can actually bound:
# the same method, the same crops, two pixel sets. A gap many times that width is
# not something a re-run would remove.
noise_margin <- function(gap, noise) abs(gap) / noise
