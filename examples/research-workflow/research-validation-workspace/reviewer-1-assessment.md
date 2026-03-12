# Reviewer Assessment

**Reviewer ID**: reviewer-1

## Assessments

### claim-1-1
- **Text**: Product development has matured into a discipline with clear, settled principles.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a subjective characterization of the state of the field. There is no empirical test that would confirm or refute whether principles are "settled." Many practitioners would disagree that the field has settled principles, given ongoing debates about methodology, measurement, and team structure.

### claim-2-0a
- **Text**: The most successful products reach users fast.
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://www.sciencedirect.com/science/article/abs/pii/S001985019800008X
     - **Title**: Key Factors in Increasing Speed to Market and Improving New Product Success Rates
     - **Excerpt**: Speed-to-market is generally positively associated with new product success, but market uncertainty moderates this effect.
     - **Supports Claim**: true
  2. **Source**: https://www.researchgate.net/publication/257875917_Speed_to_Market_for_Innovative_Products_Blessing_or_Curse
     - **Title**: Speed to Market for Innovative Products: Blessing or Curse?
     - **Excerpt**: Speed to market doesn't always equal success if the elements require more development. The relationship is conditional on market context.
     - **Supports Claim**: false
- **Reasoning**: Research shows a positive but conditional relationship between speed and success. The claim is directionally supported but overstated — speed helps in many contexts but is not a universal predictor. The word "most" makes it defensible as a general trend.

### claim-2-0b
- **Text**: Extensive upfront planning destroys value
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://www.sciencedirect.com/science/article/abs/pii/S001985019800008X
     - **Title**: Key Factors in Increasing Speed to Market
     - **Excerpt**: Time-to-market decisions play an important role in determining product success, but speed is balanced against other factors such as features, innovation, or product quality.
     - **Supports Claim**: false
  2. **Source**: https://www.pmi.org/learning/library/blending-agile-waterfall-successful-integration-10213
     - **Title**: Blending Agile And Waterfall Keys To Successful Implementation
     - **Excerpt**: Hybrid approaches combining upfront planning with agile implementation are increasingly dominant, suggesting planning has value when balanced.
     - **Supports Claim**: false
- **Reasoning**: The absolute claim that planning "destroys value" is not supported. Research shows planning has value when balanced with execution speed. The Lean Startup approach advocates learning over planning, but this is different from claiming planning destroys value.

### claim-2-1
- **Text**: the Standish Group found that 64% of software features are rarely or never used
- **Claim Type**: factual
- **Citation Valid**: false
- **Citation Notes**: The 64% statistic originates from Jim Johnson's 2002 XP conference keynote, not the 2015 CHAOS Report cited here. The 2015 CHAOS Report focuses on project success/failure rates, not feature usage. The statistic is real Standish Group data but is miscited.
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://www.mountaingoatsoftware.com/blog/are-64-of-features-really-rarely-or-never-used
     - **Title**: Are 64% of Features Really Rarely or Never Used?
     - **Excerpt**: Mike Cohn questions the 64% claim, noting it needs caveats. The statistic comes from Jim Johnson's XP 2002 keynote, not from a formal published study.
     - **Supports Claim**: false
  2. **Source**: https://scrumcrazy.wordpress.com/2015/08/06/a-response-to-mike-cohns-comments-on-64-of-software-features-rarely-or-never-used/
     - **Title**: A Response to Mike Cohn's Comments on 64% of Software Features Rarely or Never Used
     - **Excerpt**: The Standish Group study is real, with real data, and it is highly credible. Standish re-iterated in 2014 that 80% of features have low to no value.
     - **Supports Claim**: true
- **Reasoning**: The Standish Group did report this statistic, so the factual attribution is correct. However, the citation is wrong — it's from a 2002 keynote, not the 2015 CHAOS Report. The methodology has been questioned by Mike Cohn and others. Verdict is "supported" for the claim itself but citation is invalid.

### claim-2-2
- **Text**: most of what teams carefully spec out before launch is wasted effort
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: low
- **Evidence Found**:
  1. **Source**: https://scrumcrazy.wordpress.com/2015/08/06/a-response-to-mike-cohns-comments-on-64-of-software-features-rarely-or-never-used/
     - **Title**: Standish Group feature usage data
     - **Excerpt**: If 64% of features are rarely or never used, a significant portion of specification effort goes toward features that don't deliver value.
     - **Supports Claim**: true
- **Reasoning**: This claim logically follows from the 64% statistic if taken at face value. However, the inference that specification effort equals "wasted effort" is an oversimplification — specifications serve other purposes like alignment and documentation. Low confidence because it depends on accepting the 64% figure uncritically.

### claim-2-2b
- **Text**: The correct approach is to ship a minimum viable product within two weeks
- **Claim Type**: opinion
- **Citation Valid**: false
- **Citation Notes**: Eric Ries's "The Lean Startup" does not specify a two-week timeline for MVP delivery. Ries mentions IMVU's first MVP took six months. The two-week figure appears to be fabricated or confused with a different reference.
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://leanstartup.co/resources/articles/what-is-an-mvp/
     - **Title**: What Is an MVP? Eric Ries Explains
     - **Excerpt**: Ries describes MVP as the version of a new product that allows a team to collect the maximum amount of validated learning with the least effort. No specific timeline is prescribed.
     - **Supports Claim**: false
  2. **Source**: https://en.wikipedia.org/wiki/Lean_startup
     - **Title**: Lean startup - Wikipedia
     - **Excerpt**: IMVU's original MVP took six months to bring to market, which Ries described as a big improvement over spending five years before launching.
     - **Supports Claim**: false
- **Reasoning**: The Lean Startup does not prescribe a two-week MVP timeline. The book advocates for speed and learning but explicitly does not set a fixed timeline. The citation misrepresents the source material.

### claim-2-3
- **Text**: Teams that spend more than six weeks on a first release are almost certainly overbuilding.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://en.wikipedia.org/wiki/Lean_startup
     - **Title**: Lean startup - Wikipedia
     - **Excerpt**: IMVU's MVP took six months; Ries considered this fast. Many successful products have had longer initial development periods.
     - **Supports Claim**: false
- **Reasoning**: No evidence supports six weeks as a meaningful threshold. Many successful products required significantly longer initial development. The claim is an arbitrary threshold without empirical backing.

### claim-2-4
- **Text**: Speed to market has proven to be a stronger predictor of success than feature completeness in virtually every modern product category.
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://www.sciencedirect.com/science/article/abs/pii/S0737678297000623
     - **Title**: Speed-to-market and new product performance trade-offs
     - **Excerpt**: Managers must navigate tradeoffs between speed and quality/features. A fast time to market doesn't always equal success.
     - **Supports Claim**: false
  2. **Source**: https://www.researchgate.net/publication/257875917_Speed_to_Market_for_Innovative_Products_Blessing_or_Curse
     - **Title**: Speed to Market for Innovative Products: Blessing or Curse?
     - **Excerpt**: The relationship between speed and success is conditional on market context and product type.
     - **Supports Claim**: false
- **Reasoning**: Research shows speed is one factor among many, with its importance varying by context. The claim that it is "a stronger predictor... in virtually every modern product category" is not supported by research, which consistently finds context-dependent tradeoffs.

### claim-3-0
- **Text**: The way a team is organized matters more than the tools it uses.
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://terem.tech/cross-functional-teams-research/
     - **Title**: Cross-Functional Teams: A Summary of 20 Popular Studies
     - **Excerpt**: Research consistently shows that team structure and composition have significant effects on outcomes, often more impactful than tooling choices.
     - **Supports Claim**: true
- **Reasoning**: This aligns with the Agile Manifesto's principle of "individuals and interactions over processes and tools." While not a precise empirical claim, the general direction is well-supported by organizational behavior research.

### claim-3-1
- **Text**: Cross-functional squads consistently outperform specialized teams with dedicated QA, design, and backend roles
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: low
- **Evidence Found**:
  1. **Source**: https://action.deloitte.com/insight/1892/cross-functional-teams-may-boost-innovation-adaptability
     - **Title**: Cross-functional teams may boost innovation, adaptability - Deloitte
     - **Excerpt**: Teams that break down silos can outperform traditional teams by up to 30% and improve productivity by up to 35%.
     - **Supports Claim**: true
  2. **Source**: https://journals.aom.org/doi/10.5465/amd.2020.0238
     - **Title**: Staying Apart to Work Better Together - Academy of Management
     - **Excerpt**: Some researchers find that functional diversity has no effect on product quality or performance. Simply putting diverse people together isn't sufficient.
     - **Supports Claim**: false
- **Reasoning**: Evidence is mixed. Some studies show cross-functional advantages, others find no significant difference. The word "consistently" overstates the evidence. The claim is directionally supported but the absolute framing is not.

### claim-3-2
- **Text**: Amazon, Spotify, and Google all converged on this model
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://aws.amazon.com/executive-insights/content/amazon-two-pizza-team/
     - **Title**: Amazon's Two Pizza Teams - AWS Executive Insights
     - **Excerpt**: Amazon uses two-pizza teams as small, autonomous units — this is a form of cross-functional organization.
     - **Supports Claim**: true
  2. **Source**: https://www.jeremiahlee.com/posts/failed-squad-goals/
     - **Title**: Spotify's Failed #SquadGoals
     - **Excerpt**: Spotify itself moved on from the squad model. The co-author and agile coaches have been telling people not to copy it for years.
     - **Supports Claim**: false
  3. **Source**: https://fourweekmba.com/google-organizational-structure/
     - **Title**: Google Organizational Structure - FourWeekMBA
     - **Excerpt**: Google uses a matrix structure combining functional departments and product divisions, not a pure squad model.
     - **Supports Claim**: false
- **Reasoning**: Amazon does use small autonomous teams. However, Spotify abandoned its squad model and its own employees say it never fully worked. Google uses a matrix structure, not squads. The claim that all three "converged on this model" is false — at best one of three examples is accurate.

### claim-3-3
- **Text**: The two-pizza team rule remains the optimal size
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://blog.nuclino.com/two-pizza-teams-the-science-behind-jeff-bezos-rule
     - **Title**: Two-pizza teams: The science behind Jeff Bezos' rule
     - **Excerpt**: Harvard researcher J. Richard Hackman concluded that four to six is the optimal number for a project team. Ringelmann's research shows effort decreases with larger teams.
     - **Supports Claim**: true
  2. **Source**: https://polarsquad.com/blog/missapplied-and-misunderstood-2pt-rule
     - **Title**: The Misapplied and Misunderstood: Two-pizza team rule
     - **Excerpt**: The rule is often misapplied without understanding the context. Team size depends on the nature of the work.
     - **Supports Claim**: false
- **Reasoning**: Research supports small teams (5-7 people) being generally more efficient. The two-pizza rule is a reasonable heuristic. However, calling it "the optimal size" is overly absolute — optimal size depends on the task.

### claim-3-4
- **Text**: larger teams introduce coordination overhead that overwhelms any benefit from additional headcount
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://blog.nuclino.com/two-pizza-teams-the-science-behind-jeff-bezos-rule
     - **Title**: Two-pizza teams: The science behind Jeff Bezos' rule
     - **Excerpt**: Ringelmann found individual effort decreases as team size grows. Two-person teams took 36 minutes for a task while four-person teams took 52 minutes — 44% longer.
     - **Supports Claim**: true
- **Reasoning**: The Ringelmann effect and Brooks's Law both support the idea that coordination costs grow with team size. However, "overwhelms any benefit" is too absolute — there are tasks where larger teams are genuinely needed and productive.

### claim-3-4b
- **Text**: every product decision must be grounded in direct user research
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a prescriptive statement about process. While user research is widely valued, "every decision" and "must" make this an opinion about ideal practice rather than a verifiable claim.

### claim-3-5
- **Text**: Intuition-driven development is a path to failure.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://theleanstartup.com/principles
     - **Title**: The Lean Startup Methodology
     - **Excerpt**: The Lean Startup advocates for validated learning over intuition, but acknowledges that product vision and founder intuition play important roles in identifying what to test.
     - **Supports Claim**: false
- **Reasoning**: Many successful products were initially driven by strong founder intuition (iPhone, Tesla). While data-driven approaches are valuable, the absolute claim that intuition leads to failure is contradicted by numerous counter-examples.

### claim-3-6
- **Text**: teams should conduct fifteen user interviews per feature
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://www.nngroup.com/articles/interview-sample-size/
     - **Title**: How Many Participants for a UX Interview? - Nielsen Norman Group
     - **Excerpt**: Nielsen recommends 5 users per test round, with 3 rounds iteratively for a total of 15. This is for usability testing, not per-feature user interviews.
     - **Supports Claim**: false
  2. **Source**: https://www.userinterviews.com/blog/qualitative-research-sample-sizes
     - **Title**: A Guide to Sample Sizes in Qualitative UX Research
     - **Excerpt**: Recommended sample sizes vary by research type: 5-8 for usability tests, 5-30 for interviews depending on the research question.
     - **Supports Claim**: false
- **Reasoning**: The fifteen number appears to be a misapplication of Nielsen's "5 users x 3 rounds = 15" for iterative usability testing. No UX research authority recommends exactly fifteen interviews per feature as a minimum standard.

### claim-3-6b
- **Text**: apply A/B testing to every UI change
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a prescriptive process recommendation. While A/B testing is valuable, "every UI change" is impractical for most organizations and not a standard industry recommendation.

### claim-3-7
- **Text**: any team not running continuous experiments is effectively operating blind
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: Hyperbolic value judgment. Experimentation is valuable, but many successful teams operate with limited experimentation. "Operating blind" is subjective rhetoric, not a verifiable claim.

### claim-4-1
- **Text**: Technical debt behaves like financial debt: it compounds.
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://ctomagazine.com/prioritize-technical-debt-ctos/
     - **Title**: Prioritize Technical Debt for Long-Term Wins - CTO Magazine
     - **Excerpt**: Technical debt compounds over time, making future changes increasingly difficult and costly.
     - **Supports Claim**: true
- **Reasoning**: The compounding metaphor is widely accepted in the industry and supported by practitioner experience. Ward Cunningham, who coined the term, used the financial debt analogy intentionally. However, the analogy has limits — technical debt doesn't have a precise interest rate.

### claim-4-2
- **Text**: Zero debt is the correct target, and teams should allocate exactly 20% of every sprint to reduction.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://docs.gitscrum.com/en/best-practices/managing-technical-debt-in-agile-teams/
     - **Title**: Technical Debt Agile - Sprint Allocation & Paydown
     - **Excerpt**: Experts recommend 15-20% allocation, but the exact figure varies by product maturity and current debt level.
     - **Supports Claim**: false
  2. **Source**: https://www.whitespectre.com/ideas/tech-debt-tech20-explained/
     - **Title**: Tech20 Explained - Whitespectre
     - **Excerpt**: For each company it will vary depending on the current state of the tech — so maybe your Tech20 is Tech15.
     - **Supports Claim**: false
- **Reasoning**: The 20% figure is a common guideline but not a universal rule. "Exactly 20%" and "zero debt" are both too rigid — the appropriate allocation depends on context. Some deliberate technical debt is strategically valuable.

### claim-4-3
- **Text**: Any team carrying more than one sprint's worth of accumulated debt is in a death spiral from which incremental fixes cannot recover.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://www.scrum.org/resources/blog/technical-debt-scrum-who-responsible
     - **Title**: Technical Debt & Scrum: Who Is Responsible? - Scrum.org
     - **Excerpt**: Technical debt can be managed through regular allocation and prioritization. Teams regularly recover from significant accumulated debt.
     - **Supports Claim**: false
- **Reasoning**: This is an extreme claim with no empirical support. Many teams carry significant technical debt and recover through sustained effort. The "death spiral" framing is hyperbolic.

### claim-4-4
- **Text**: a full rewrite is always preferable to gradual refactoring because rewrites eliminate accumulated architectural compromise completely rather than merely patching symptoms
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/
     - **Title**: Things You Should Never Do, Part I - Joel on Software
     - **Excerpt**: Joel Spolsky argues a functioning application should never be rewritten from scratch. Netscape's rewrite caused a 3-year delay and arguably led to the company's downfall.
     - **Supports Claim**: false
  2. **Source**: https://remesh.blog/refactor-vs-rewrite-7b260e80277a
     - **Title**: Refactor vs. Rewrite
     - **Excerpt**: The correct answer depends on circumstances. Sometimes refactoring is better, sometimes rewriting. There is no universal answer.
     - **Supports Claim**: false
  3. **Source**: https://medium.com/@herbcaudill/lessons-from-6-software-rewrite-stories-635e4c8f7c22
     - **Title**: Lessons from 6 software rewrite stories
     - **Excerpt**: Analysis of six real rewrite cases shows mixed outcomes — some succeeded, some failed catastrophically.
     - **Supports Claim**: false
- **Reasoning**: This is one of the most clearly contradicted claims in the document. Joel Spolsky's famous essay and numerous case studies show that rewrites frequently fail. The word "always" makes this claim indefensible.

### claim-4-4b
- **Text**: Product quality is inseparable from measurement.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a philosophical position about the nature of quality. It echoes Deming and the quality movement but is not empirically testable.

### claim-4-5
- **Text**: If a feature cannot be measured, it should not be built.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: Prescriptive process recommendation. Many valuable features (accessibility improvements, code quality, developer experience) are difficult to measure directly but widely acknowledged as important.

### claim-4-5b
- **Text**: Every feature needs a pre-defined success metric with a quantitative threshold established before development begins.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: Prescriptive process recommendation. While pre-defining metrics is a good practice, "every feature" and "before development begins" is an absolute that most teams don't follow strictly.

### claim-4-6
- **Text**: OKRs are the only goal-setting framework that works at scale
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://dataon.com/en-en/blog/okrs-vs-other-goal-systems-definitions-differences-and-use-cases/
     - **Title**: OKRs vs KPIs, SMART Goals & BSC: Key Differences Explained
     - **Excerpt**: Multiple goal-setting frameworks work effectively at scale, including Balanced Scorecards, KPIs, SMART Goals, and V2MOM.
     - **Supports Claim**: false
  2. **Source**: https://asana.com/resources/okr-vs-kpi
     - **Title**: OKR vs. KPI - Asana
     - **Excerpt**: No framework is universally better. Each has its place depending on company needs.
     - **Supports Claim**: false
- **Reasoning**: Balanced Scorecards, KPIs, SMART goals, V2MOM (Salesforce), and other frameworks are widely used at scale successfully. The claim that OKRs are "the only" framework that works is demonstrably false.

### claim-4-7
- **Text**: teams should focus exclusively on activation rate, retention, and NPS
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://asana.com/resources/okr-vs-kpi
     - **Title**: OKR vs. KPI - Asana
     - **Excerpt**: Companies track a wide variety of metrics depending on their business model, including revenue, churn, LTV, CAC, engagement, and many others.
     - **Supports Claim**: false
- **Reasoning**: While activation, retention, and NPS are important metrics, "exclusively" is too narrow. Revenue, conversion rates, LTV, engagement metrics, and many others are equally important depending on business context.

### claim-4-8
- **Text**: vanity metrics like page views and raw sign-up counts are actively misleading
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://theleanstartup.com/principles
     - **Title**: The Lean Startup Methodology
     - **Excerpt**: Ries distinguishes between vanity metrics (which look good on paper) and actionable metrics (which drive decisions). Vanity metrics can mislead teams about real progress.
     - **Supports Claim**: true
- **Reasoning**: The Lean Startup and broader product community widely agree that vanity metrics can be misleading. However, "actively misleading" is stronger than "less useful" — page views and sign-ups can be meaningful in certain contexts.

### claim-5-1
- **Text**: Agile has won the methodology debate decisively.
- **Claim Type**: analytical
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: medium
- **Evidence Found**:
  1. **Source**: https://www.scrum.org/resources/blog/depth-evidence-based-business-case-agile
     - **Title**: The Evidence-Based Business Case For Agile - Scrum.org
     - **Excerpt**: Agile methods improve outcomes in quality, satisfaction, and productivity. Agile teams deliver more value and have higher team morale.
     - **Supports Claim**: true
- **Reasoning**: Agile has become the dominant methodology, but "decisively" overstates the case. Hybrid approaches are increasingly popular, and pure waterfall still has valid use cases. The debate has shifted but not ended.

### claim-5-2
- **Text**: Waterfall is dead, and every successful product team today uses some form of Agile.
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://asana.com/resources/waterfall-project-management-methodology
     - **Title**: Guide to Waterfall Methodology - Asana
     - **Excerpt**: Pure Waterfall is at approximately 44% adoption in 2025. Microsoft and IBM use Waterfall for certain products. Manufacturing and construction rely heavily on waterfall.
     - **Supports Claim**: false
  2. **Source**: https://www.pmi.org/learning/library/blending-agile-waterfall-successful-integration-10213
     - **Title**: Blending Agile And Waterfall - PMI
     - **Excerpt**: Hybrid approaches combining waterfall and agile are increasingly dominant at 35-40%.
     - **Supports Claim**: false
- **Reasoning**: Waterfall is not dead — it's used at approximately 44% adoption. Many successful companies use waterfall or hybrid approaches. The claim is demonstrably false.

### claim-5-3
- **Text**: Scrum should be the default framework choice
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a prescriptive recommendation. Scrum is the most popular Agile framework, but "should be the default" is a judgment call that depends on team context.

### claim-5-4
- **Text**: SAFe as the appropriate scaling mechanism for enterprise environments
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://www.pmi.org/disciplined-agile/da-flex-toc/the-good-the-bad-and-the-ugly-of-safe
     - **Title**: SAFe: The Good, the Bad, and the Ugly - PMI
     - **Excerpt**: SAFe has received criticism for being too hierarchical and inflexible. It is described as improved waterfall rather than true Agile.
     - **Supports Claim**: false
  2. **Source**: https://safedelusion.com/
     - **Title**: SAFe Delusion
     - **Excerpt**: Prominent SAFe figures have distanced themselves. ThoughtWorks explicitly discourages SAFe since 2015. Executives share case studies of failed SAFe adoptions.
     - **Supports Claim**: false
  3. **Source**: https://mariachec.medium.com/safe-controversy-is-it-cool-to-hate-on-safe-6920f7765f60
     - **Title**: SAFe Controversy - Medium
     - **Excerpt**: SAFe is the most common approach to scaling agile at 30%, but faces widespread criticism from agile practitioners.
     - **Supports Claim**: false
- **Reasoning**: SAFe is widely used but also widely criticized. Prominent Agile figures, ThoughtWorks, and SAFe's own early contributors have distanced themselves from it. Calling it "the appropriate" mechanism ignores significant controversy and alternatives like LeSS, Nexus, and Spotify-style approaches.

### claim-5-5
- **Text**: Teams that reject formal Agile methodology in favor of ad-hoc or custom processes produce measurably worse outcomes across every dimension — velocity, quality, and team satisfaction alike
- **Claim Type**: factual
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: supported
- **Confidence**: low
- **Evidence Found**:
  1. **Source**: https://www.scrum.org/resources/blog/depth-evidence-based-business-case-agile
     - **Title**: The Evidence-Based Business Case For Agile - Scrum.org
     - **Excerpt**: Agile teams deliver more value, have higher team morale, and more satisfied stakeholders than less Agile teams.
     - **Supports Claim**: true
  2. **Source**: https://www.danielrusso.org/evidence-based-approaches-agile-success/
     - **Title**: How Evidence-Based Approaches in Agile Drive Success
     - **Excerpt**: Agile methods improve quality, satisfaction, and productivity without significant cost increase.
     - **Supports Claim**: true
- **Reasoning**: Research supports Agile advantages over ad-hoc approaches. However, "across every dimension" and "measurably worse" are overstated. Some custom processes (like Basecamp's Shape Up) have produced excellent results. The claim's absolute framing is not fully supported.

### claim-6-1
- **Text**: These principles represent settled knowledge backed by decades of industry data.
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: As this review demonstrates, many of the document's claims are contested, contradicted, or overstated. The field of product development is far from "settled" — it remains an area of active debate and evolving practice.

### claim-6-2
- **Text**: They should be adopted without significant modification regardless of company size, domain, or market context
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: contradicted
- **Confidence**: high
- **Evidence Found**:
  1. **Source**: https://www.sciencedirect.com/science/article/abs/pii/S0737678297000623
     - **Title**: Speed-to-market and new product performance trade-offs
     - **Excerpt**: Market uncertainty moderates the effect of speed on success, demonstrating that context matters significantly.
     - **Supports Claim**: false
- **Reasoning**: Context-dependence is one of the most consistent findings across all the research reviewed. Claiming universal applicability contradicts the nuanced findings of virtually every study cited in this review.

### claim-6-3
- **Text**: the fundamentals of building products people want do not change with circumstance
- **Claim Type**: opinion
- **Citation Valid**: N/A
- **Citation Notes**:
- **Verdict**: unverifiable
- **Confidence**: high
- **Evidence Found**:
- **Reasoning**: This is a philosophical claim about universal principles. It cannot be empirically tested in its current form.
