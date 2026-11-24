/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_OVERLAP_POLICY_H
#define DISTQLDPC_CC_OVERLAP_POLICY_H

#include "cc_overlap.h"

/* The policy owner points to the borrowed view for this level. */
static inline void cc_overlap_policy(void *owner, int q, bool add) {
    cc_update_overlap((struct cc_overlap_view *)owner, q, add);
}
#endif
