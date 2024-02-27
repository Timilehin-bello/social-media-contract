// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MyNFT } from "./MyNFT.sol";


/**
 * @title SocialMedia
 *@author [Timilehin Bello ](https://github.com/Timilehin-bello)
 * @dev Contract for managing social media users and posts
 */
contract SocialMedia {
    struct User {
        string username;
        uint256 followersCount;
        uint256 followingCount;
        uint256 walletBalance;
        bool exists;
        uint256 postCount;
        uint256 createdAt;
    }

    struct Post {
        uint256 tokenId;
        string description;
        address author;
        uint256 likes;
        uint256 commentCount;
        uint256 createdAt;
    }

    struct Comment {
        string content;
        uint256 postId;
        address author;
        uint256 createdAt;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => mapping(uint256 => Comment)) public postComments;
    mapping(uint256 => mapping(address => bool)) public postLikes;
    mapping(address => mapping(address => bool)) public followers;
    uint256 public postCounter;
    MyNFT public nftCollection;

    event UserRegistered(address indexed user, string username, uint256 time);
    event PostCreated(address indexed user, uint256 indexed postId, uint256 indexed tokenId, address tokenAddress);
    event PostLiked(address indexed user, uint256 postId);
    event PostUnliked(address indexed user, uint256 postId);
    event UserFollowed(address indexed follower, address indexed followed);
    event UserUnfollowed(address indexed follower, address indexed followed);
    event PostDeleted(address indexed user, uint256 indexed postId);
    event CommentAdded(address indexed user, uint256 indexed postId, uint256 commentId);

    constructor() {
        nftCollection = new MyNFT("SOCIAL MEDIA COLLECTION", "SMC");
        postCounter = 0;
    }

    function registerUser(string memory _username) external {
        require(!users[msg.sender].exists, "User already registered");
        users[msg.sender] = User(_username, 0, 0, 0, true, 0, block.timestamp);
        emit UserRegistered(msg.sender, _username, block.timestamp);
    }

    function createPost(string memory _description, string calldata _tokenUri) external {
        require(users[msg.sender].exists, "Unauthorized");
        require(bytes(_tokenUri).length >= 8, "URI too short");
        
        nftCollection.mintNft(_tokenUri, msg.sender);
        posts[postCounter] = Post(postCounter, _description, msg.sender, 0, 0, block.timestamp);
        postCounter++;
        emit PostCreated(msg.sender, postCounter, postCounter, address(nftCollection));
    }

    function toggleLike(uint256 _postId) external {
        require(users[msg.sender].exists, "Unauthorized");
        require(posts[_postId].createdAt != 0, "Post not found");
        
        if (!postLikes[_postId][msg.sender]) {
            postLikes[_postId][msg.sender] = true;
            posts[_postId].likes += 1;
            emit PostLiked(msg.sender, _postId);
        } else {
            postLikes[_postId][msg.sender] = false;
            posts[_postId].likes -= 1;
            emit PostUnliked(msg.sender, _postId);
        }
    }

    function addComment(uint256 _postId, string calldata _content) external {
        require(users[msg.sender].exists, "Unauthorized");
        require(posts[_postId].createdAt != 0, "Post not found");
        
        uint256 commentCount = posts[_postId].commentCount;
        postComments[_postId][commentCount] = Comment(_content, _postId, msg.sender, block.timestamp);
        posts[_postId].commentCount += 1;
        emit CommentAdded(msg.sender, _postId, commentCount);
    }

    function toggleFollow(address _user) external {
        require(users[msg.sender].exists, "Unauthorized");
        require(users[_user].exists, "User not found");
        
        if (followers[_user][msg.sender]) {
            followers[_user][msg.sender] = false;
            users[_user].followersCount -= 1;
            users[msg.sender].followingCount -= 1;
            emit UserUnfollowed(msg.sender, _user);
        } else {
            followers[_user][msg.sender] = true;
            users[_user].followersCount += 1;
            users[msg.sender].followingCount += 1;
            emit UserFollowed(msg.sender, _user);
        }
    }


    function deletePost(uint256 _postId) external {
        require(users[msg.sender].exists, "Unauthorized");
        require(posts[_postId].createdAt != 0, "Post not found");
        require(posts[_postId].author == msg.sender, "Unauthorized");
        
        delete posts[_postId];
        emit PostDeleted(msg.sender, _postId);
    }
}
