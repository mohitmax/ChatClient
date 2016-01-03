//
//  ViewController.m
//  ChatClient
//
//  Created by Mohit Sadhu on 12/31/15.
//  Copyright © 2015 Mohit Sadhu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initNetworkCommunication];
    
    _messages = [[NSMutableArray alloc] init];
}

#pragma mark - Private methods
 - (void)initNetworkCommunication
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", 80, &readStream, &writeStream);

    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
}

- (void)messageReceived: (NSString *)message
{
    [_messages addObject:message];
    [self.tableview reloadData];
    
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:_messages.count - 1
                                                   inSection:0];
    [self.tableview scrollToRowAtIndexPath:topIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}

#pragma mark - Action methods
- (IBAction)joinChatTapped:(id)sender
{
    NSString *response = @"";
    if (_inputNameTextfield.text != nil && ![_inputNameTextfield.text isEqualToString:@""])
    {
        response = [NSString stringWithFormat:@"iam:%@",_inputNameTextfield.text];
        NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [_outputStream write:[data bytes] maxLength:data.length];
        
        [self.view bringSubviewToFront:self.chatView];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Missing chat name." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
        
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
}

- (IBAction)sendMessageTapped:(id)sender
{
    NSString *response = @"";
    
    if (_inputMessageTextfield.text != nil && ![_inputMessageTextfield.text isEqualToString:@""])
    {
        response = [NSString stringWithFormat:@"msg:%@", _inputMessageTextfield.text];
        NSData *data = [NSData dataWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [_outputStream write:data.bytes maxLength:data.length];
        
        _inputMessageTextfield.text = @"";
    }
}

#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"ChatCellIdentifier";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    NSString *s = (NSString *)[_messages objectAtIndex:indexPath.row];
    cell.textLabel.text = s;
    
    return cell;
}

#pragma mark - NSStream delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"Stream event: %lu", (unsigned long)eventCode);
    
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Has bytes available");
            //Check if the event comes from the inputStream that we have set up.
            if (aStream == _inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;
                
                while ([_inputStream hasBytesAvailable])
                {
                    //read bytes from the stream and collect them in a buffer
                    len = [_inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        //Transform buffer into a string
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        output = [output stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                        output = [output stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                        
                        if (output)
                        {
                            NSLog(@"Server said: %@", output);
                            [self messageReceived:output];
                        }
                    }
                }
            }
            
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Stream ended");
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            break;
            
        default:
            NSLog(@"Unknown event");
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
