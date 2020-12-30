---
title: "Scheduled Events"
date: 2020-11-18T12:12:25-05:00
draft: false
---

### ACA Shop Scheduled Events
The `BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents` class is called by Enroll's `TimeKeeper`, which is itself triggered by the `Subscribers::DateChange` listener class. A cron job is responsible for delivering the adv
The processes ran everyday are:
 * open_enrollment_begin
 * open_enrollment_end
 * benefit_begin
 * benefit_end
 * benefit_termination
 * benefit_termination_pending
 * benefit_renewal
