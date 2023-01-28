trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            //Create patient follow up events for same time every month
            List<Event> eventsToSchedule = new List<Event>();
            for(Opportunity opp: Trigger.new){
                //Confirm Closed Won Opportunity which has First Date of Analysis
                if ((opp.StageName == 'Closed Won') && (Trigger.oldMap.get(opp.Id).StageName != 'Closed Won') && (opp.First_Date_of_Analysis__c != NULL)){
                    //12 iterations for each month
                    for(Integer i=1;i<=12;i++){
                        //Default eventDate preparation - This will reflect DST adjustments as per Salesforce feature.
                        DateTime newEventDate = opp.First_Date_of_Analysis__c.addMonths(i);
                        //Reference Time.
                        Decimal FirstAnalysisTime = Decimal.valueOf(opp.First_Date_of_Analysis__c.format('HH.mm'));
                        //DST adjusted time by SF. This has to be disabled in some use cases hence this code.
                        Decimal newEventTime = Decimal.valueOf(newEventDate.format('HH.mm'));
                        //Time difference between DST adjusted value and reference time
                        Decimal timeDifference = FirstAnalysisTime - newEventTime;
                        //Adjust the event time to avoid DST changes.
                        newEventDate = newEventDate.addHours(Integer.valueOf(timeDifference));
                        eventsToSchedule.add(
                            new Event(
                                OwnerId = opp.CreatedById,
                                WhatId = opp.Id,
                                StartDateTime = newEventDate,
                                EndDateTime = newEventDate.addHours(1),
                                ActivityDateTime = newEventDate,
                                Subject = 'Patient Follow Up'
                            )
                        );
                    }
                }
            }
            insert eventsToSchedule;
        }
    }

}