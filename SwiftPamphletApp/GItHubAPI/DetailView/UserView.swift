//
//  UserView.swift
//  PresentSwiftUI
//
//  Created by Ming Dai on 2021/11/10.
//

import SwiftUI
import MarkdownUI

struct UserView: View {
    @EnvironmentObject var appVM: AppVM
    @StateObject var vm: UserVM
    var isShowUserEventLink = true
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack() {
                    AsyncImageWithPlaceholder(size: .normalSize, url: vm.user.avatarUrl)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(vm.user.name ?? vm.user.login).font(.system(.title))
                            Text("(\(vm.user.login))")
                            Text("订阅者 \(vm.user.followers) 人，仓库 \(vm.user.publicRepos) 个")
                        }
                        HStack {
                            ButtonGoGitHubWeb(url: vm.user.htmlUrl, text: "在 GitHub 上访问")
                            if vm.user.location != nil {
                                Text("居住：\(vm.user.location ?? "")").font(.system(.subheadline))
                            }
                        }
                    } // end VStack
                } // end HStack
                
                if vm.user.bio != nil {
                    Text("简介：\(vm.user.bio ?? "")")
                }
                HStack {
                    if vm.user.blog != nil {
                        if !vm.user.blog!.isEmpty {
                            Text("博客：\(vm.user.blog ?? "")")
                            ButtonGoGitHubWeb(url: vm.user.blog ?? "", text: "访问")
                        }
                    }
                    if vm.user.twitterUsername != nil {
                        Text("Twitter：")
                        ButtonGoGitHubWeb(url: "https://twitter.com/\(vm.user.twitterUsername ?? "")", text: "@\(vm.user.twitterUsername ?? "")")
                    }
                    
                }
            }
            Spacer()
        }
        .alert(vm.errMsg, isPresented: $vm.errHint, actions: {})
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 0, trailing: 10))
        .onAppear {
            vm.doing(.inInit)
            
            appVM.devsNotis[vm.userName] = 0
            appVM.calculateDevsCountNotis()
        }
        .frame(minWidth: SPC.detailMinWidth)
        
        TabView {
            UserEventView(events: vm.events, isShowUserEventLink: isShowUserEventLink)
            .tabItem {
                Text("事件")
            }
            UserEventView(events: vm.receivedEvents, isShowActor: true, isShowUserEventLink: isShowUserEventLink)
                .tabItem {
                    Text("Ta 接收的事件")
                }
                .onAppear {
                    vm.doing(.inReceivedEvent)
                }
        }
        .frame(minWidth: SPC.detailMinWidth)
        Spacer()
        
        
        
    }
}

struct UserEventView: View {
    var events: [EventModel]
    var isShowActor = false
    var isShowUserEventLink = true
    
    var body: some View {
        List {
            ForEach(events) { event in
                
                if isShowUserEventLink == true {
                    NavigationLink {
                        UserEventLinkDestination(event: event)
                    } label: {
                        AUserEventLabel(event: event, isShowActor: isShowActor)
                    } // end NavigationLink
                } else {
                    AUserEventLabel(event: event, isShowActor: isShowActor)
                }
            } // end ForEach
        }//  end List
    } // end body
} // end struct

// MARK: 碎视图

struct ListCommits: View {
    var event: EventModel
    var body: some View {
        ForEach(event.payload.commits ?? [PayloadCommitModel](), id: \.self) { c in
            ButtonGoGitHubWeb(url: "https://github.com/\(event.repo.name)/commit/\(c.sha ?? "")", text: "commit: \(c.message ?? "")")
        }
    }
}

struct UserEventLinkDestination: View {
    var event: EventModel
    var body: some View {
        VStack {
            if event.payload.issue?.number != nil {
                IssueView(vm: IssueVM(repoName: event.repo.name, issueNumber: event.payload.issue?.number ?? 0))
            } else {
                RepoView(vm: RepoVM(repoName: event.repo.name), type: .readme)
            }
        }
    }
}

struct AUserEventLabel: View {
    var event: EventModel
    var isShowActor: Bool = false
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(event.createdAt.prefix(10)).font(.system(.footnote))
                ButtonGoGitHubWeb(url: "https://github.com/\(event.repo.name)", text: event.repo.name, bold: true)
                if event.payload.issue?.number != nil {
                    ButtonGoGitHubWeb(url: "https://github.com/\(event.repo.name)/issues/\(String(describing: event.payload.issue?.number ?? 0))", text: "Issue")
                }

                Text(event.type)
                Text(event.payload.action ?? "")
                if isShowActor == true {
                    AsyncImageWithPlaceholder(size: .tinySize, url: event.actor.avatarUrl)
                    
                    Text(event.actor.login).bold()

                } // end if
                
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            
            if event.payload.issue?.number != nil {
                Text(event.payload.issue?.title ?? "").bold()
                Markdown(Document(event.payload.issue?.body ?? ""))
            }
            
            if event.payload.commits != nil {
                ListCommits(event: event)
            }
            
            if event.payload.pullRequest != nil {
                Text(event.payload.pullRequest?.title ?? "").bold()
                Markdown(Document(event.payload.pullRequest?.body ?? ""))
            }

            if event.payload.description != nil {
                Markdown(Document(event.payload.description ?? ""))
            }
        } // end VStack
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
    }
}
