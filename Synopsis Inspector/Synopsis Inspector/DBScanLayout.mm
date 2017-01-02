//
//  DBScanLayout.m
//  Synopsis Inspector
//
//  Created by vade on 12/21/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "DBScanLayout.h"
#include "dbscan_vp.h"

@interface DBScanLayout ()
{
    std::shared_ptr<clustering::Dataset> mDataSet;
    std::shared_ptr<clustering::DBSCAN_VP> mDBScanVP;
}

@end

@implementation DBScanLayout

- (instancetype) init
{
    return [self initWithData:nil];
}

- (instancetype) initWithData:(NSArray<NSArray<NSNumber*> *>*)data
{
    self = [super init];
    if(self)
    {
        NSUInteger numberOfFeatures = [data count];
        NSUInteger featureLength = [data[0] count];
        
        mDataSet = clustering::Dataset::create();
        
        mDataSet->resize(numberOfFeatures);

        std::vector<float> featureVector;
        featureVector.resize(featureLength);

        for(NSArray* featureArray in data)
        {
            featureVector.clear();
            
            for(NSNumber* featureWeight in featureArray)
            {
                double feature = [featureWeight floatValue];
                
                featureVector.push_back(feature);
            }
            
            mDataSet->append_feature(featureVector);
        }
        
        mDBScanVP = std::make_shared<clustering::DBSCAN_VP>(mDataSet);
        
        mDBScanVP->fit();
        std::vector<double> epsilon = mDBScanVP->predict_eps(2);
        
        double avgEpsilon = 0;
        for(int i = 0; i < epsilon.size(); i++)
        {
            avgEpsilon += epsilon[i];
        }
        
        avgEpsilon /= epsilon.size();
        avgEpsilon *= 0.75;
        
        mDBScanVP->predict(avgEpsilon, 2);
        
        
    
        
    }
    return self;
}
@end
