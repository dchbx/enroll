---
title: "Sponsored Benefits"
section: "Components"
date: 2020-11-18T12:12:09-05:00
draft: false
---

Sponsored Benefitsis a [Rails Engine](https://guides.rubyonrails.org/engines.html) found in the components/ folder of Enroll. At the heart of the Sponsored Benefits Engine lies the *Broker Quoting Tool*.

# Quoting Tool

Brokers can create model draft plan years that illustrate different plan offering scenarios. While creating a draft plan year, the broker can change plan offering models (all plans from a metal level, all plans from a carrier, one plan) and contributions (percentages and reference plan selection) to see immediate updated cost modelling for employer aggregate monthly costs and reports of each employee’s monthly cost in the reference plan, lowest cost available plan, and highest cost available plan. The broker can create/modify these draft plan years directly within the employer’s account so that the employer can log in, review the draft plan year, and make modifications themselves, if they choose.

A Broker Quoting Tool is designed to work as an interactive ‘scratch pad’ on laptop and tablet computers, that helps brokers develop and customize benefit coverage optimal for prospective and renewing employers.

Starting with minimal roster information—employee counts and ages—the tool enables brokers to build out ‘what if’ scenarios with alternative coverage and contribution benefit packages, performing comparisons organized either by cost or benefit criteria.

When complete, these scenarios may be transmitted to the employer for review and selection. When selected by the employer, the scenario automatically generates the plan year application ready to submittal to the exchange.

In their accounts, brokers are provided a dashboard where they may track employer prospects and their quotes. The dashboard supports quote cloning, which provides convenience for creating templates for employer profiles, or generation of year-over-year quotes for current clients.


*Relevant Cucumbers*
[Broker Cucumbers](https://github.com/dchbx/enroll/tree/master/features/brokers) - all files ending with .feature